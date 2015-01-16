require 'rubygems'
require 'eventmachine'
require 'uri'

module EventMachine
  module Protocols
    module RedisSentinel
      include EM::Deferrable

      ##
      # constants
      #########################

      OK      = "OK".freeze
      MINUS    = "-".freeze
      PLUS     = "+".freeze
      COLON    = ":".freeze
      DOLLAR   = "$".freeze
      ASTERISK = "*".freeze
      DELIM    = "\r\n".freeze

      BOOLEAN_PROCESSOR = lambda{|r| %w(1 OK).include? r.to_s}

      REPLY_PROCESSOR = {
        "exists"    => BOOLEAN_PROCESSOR,
        "sismember" => BOOLEAN_PROCESSOR,
        "sadd"      => BOOLEAN_PROCESSOR,
        "srem"      => BOOLEAN_PROCESSOR,
        "smove"     => BOOLEAN_PROCESSOR,
        "zadd"      => BOOLEAN_PROCESSOR,
        "zrem"      => BOOLEAN_PROCESSOR,
        "move"      => BOOLEAN_PROCESSOR,
        "setnx"     => BOOLEAN_PROCESSOR,
        "del"       => BOOLEAN_PROCESSOR,
        "renamenx"  => BOOLEAN_PROCESSOR,
        "expire"    => BOOLEAN_PROCESSOR,
        "select"    => BOOLEAN_PROCESSOR,
        "hexists"   => BOOLEAN_PROCESSOR,
        "hset"      => BOOLEAN_PROCESSOR,
        "hdel"      => BOOLEAN_PROCESSOR,
        "hsetnx"    => BOOLEAN_PROCESSOR,
        "hgetall"   => lambda{|r| Hash[*r]},
        "info"      => lambda{|r|
          info = {}
          r.each_line do |line|
            line.chomp!
            unless line.empty?
              k, v = line.split(":", 2)
              info[k.to_sym] = v
            end
          end
          info
        }
      }

      ALIASES = {
        # 'alias' => 'command'
      }

      DISABLED_COMMANDS = {
        "monitor" => true,
        "sync"    => true
      }

      def ping(&blk)
        call_command(['ping'], &blk)
      end

      def sentinel_masters(&blk)
        call_command(['sentinel', 'masters'], &blk)
      end

      def sentinel_master(master, &blk)
        call_command(['sentinel', 'master', master], &blk)
      end

      def sentinel_slaves(master, &blk)
        call_command(['sentinel', 'slaves', master], &blk)
      end

      def sentinel_get_master_addr_by_name(master, &blk)
        call_command(['sentinel', 'get-master-addr-by-name', master], &blk)
      end

      def sentinel_reset(pattern)
        call_command(['sentinel', 'reset', pattern]) do |blk|
          yield blk if block_given?
        end
      end

      def sentinel_failover(master)
        call_command(['sentinel', 'failover', master]) do |blk|
          yield blk if block_given?
        end
      end

      def sentinel_monitor(name, ip, port, quorum)
        call_command(['sentinel', 'monitor', name, ip, port, quorum]) do |blk|
          yield blk if block_given?
        end
      end

      def sentinel_remove(name)
        call_command(['sentinel', 'remove', name]) do |blk|
          yield blk if block_given?
        end
      end

      def sentinel_set(name, option, value)
        call_command(['sentinel', 'set', name, option, value]) do |blk|
          yield blk if block_given?
        end
      end

      def auth(password, &blk)
        @password = password
        call_command(['auth', password], &blk)
      end

      def quit(&blk)
        call_command(['quit'], &blk)
      end

      def errback(&blk)
        @error_callback = blk
      end
      alias_method :on_error, :errback

      def error(klass, msg)
        err = klass.new(msg)
        err.code = msg if err.respond_to?(:code)
        @error_callback.call(err)
      end

      def before_reconnect(&blk)
        @reconnect_callbacks[:before] = blk
      end

      def after_reconnect(&blk)
        @reconnect_callbacks[:after] = blk
      end

      def method_missing(*argv, &blk)
        call_command(argv, &blk)
      end

      def call_command(argv, &blk)
        callback { raw_call_command(argv, &blk) }
      end

      def raw_call_command(argv, &blk)
        argv[0] = argv[0].to_s unless argv[0].kind_of? String
        argv[0] = argv[0].downcase
        send_command(argv)
        @sentinel_callbacks << [REPLY_PROCESSOR[argv[0]], blk]
      end

      def call_commands(argvs, &blk)
        callback { raw_call_commands(argvs, &blk) }
      end

      def raw_call_commands(argvs, &blk)
        if argvs.empty?  # Shortcut
          blk.call []
          return
        end

        argvs.each do |argv|
          argv[0] = argv[0].to_s unless argv[0].kind_of? String
          send_command argv
        end
        # FIXME: argvs may contain heterogenous commands, storing all
        # REPLY_PROCESSORs may turn out expensive and has been omitted
        # for now.
        @sentinel_callbacks << [nil, argvs.length, blk]
      end

      def send_command(argv)
        argv = argv.dup

        error DisabledCommand, "#{argv[0]} command is disabled" if DISABLED_COMMANDS[argv[0]]
        argv[0] = ALIASES[argv[0]] if ALIASES[argv[0]]

        if argv[-1].is_a?(Hash)
          argv[-1] = argv[-1].to_a
          argv.flatten!
        end

        command = ["*#{argv.size}"]
        argv.each do |v|
          v = v.to_s
          command << "$#{get_size(v)}"
          command << v
        end
        command = command.map {|cmd| cmd + DELIM}.join

        @logger.debug { "*** sending: #{command}" } if @logger
        send_data command
      end

      ##
      # errors
      #########################

      class DisabledCommand < StandardError; end
      class ParserError < StandardError; end
      class ProtocolError < StandardError; end
      class ConnectionError < StandardError; end

      class SentinelError < StandardError
        attr_accessor :code

        def initialize(*args)
          args[0] = "Sentinel server returned error code: #{args[0]}"
          super
        end
      end

      ##
      # em hooks
      #########################

      class << self
        def parse_url(url)
          begin
            uri = URI.parse(url)
            {
              :host => uri.host,
              :port => uri.port,
              :password => uri.password
            }
          rescue
            error ArgumentError, 'invalid sentinel url'
          end
        end

        def connect(options, &callback)
          if options[:sentinels].is_a?(Array)
            options[:sentinels].each do |sentinel|
              if sentinel.is_a?(Hash)
                sentinel[:host] ||= '127.0.0.1'
                sentinel[:port]   = (sentinel[:port] || 26379).to_i
                EM.connect(sentinel[:host], sentinel[:port], self) do |sentinel_connection|
                  sentinel_connection.sentinel_get_master_addr_by_name('sentinel_mycluster') do |master|
                    redis_connection = EM.connect(master[0], master[1], EM::Protocols::Redis)
                    callback.call(redis_connection) if callback
                  end
                end
                true
              else
                error ArgumentError, 'a sentinel must be a Hash'
              end
            end
          else
            error ArgumentError, 'sentinels must be an Array'
          end
        end
      end

      def initialize(options = {})
        @host           = options[:host]
        @port           = options[:port]
        @password       = options[:password]
        @auto_reconnect = options[:auto_reconnect].nil? ? true : options[:auto_reconnect]
        @logger         = options[:logger]
        @sentinels      = options[:sentinels]

        @error_callback = lambda do |err|
          raise err
        end
        @reconnect_callbacks = {
          :before => lambda{},
          :after  => lambda{}
        }
        @values = []
      end

      def auth
        # auth goes to the front of the line
        callbacks = @callbacks
        @callbacks = []
        call_command(["auth", @password]) if @password
        callbacks.each { |block| callback &block }
      end
      private :auth

      def connection_completed
        @logger.debug { "Connected to #{@host}:#{@port}" } if @logger
        @reconnect_callbacks[:after].call if @reconnecting
        @sentinel_callbacks = []
        @multibulk_n     = false
        @reconnecting    = false
        @connected       = true
        auth
        succeed
      end

      # 19Feb09 Switched to a custom parser, LineText2 is recursive and can cause
      #         stack overflows when there is too much data.
      # include EM::P::LineText2
      def receive_data(data)
        (@buffer ||= '') << data
        while index = @buffer.index(DELIM)
          begin
            line = @buffer.slice!(0, index+2)
            process_cmd line
          rescue ParserError
            @buffer[0...0] = line
            break
          end
        end
      end

      def process_cmd(line)
        @logger.debug { "*** processing #{line}" } if @logger
        # first character of buffer will always be the response type
        reply_type = line[0, 1]
        reply_args = line.slice(1..-3) # remove type character and \r\n
        case reply_type
        # e.g. -ERR
        when MINUS
          # server ERROR
          dispatch_error(reply_args)
        # e.g. +OK
        when PLUS
          dispatch_response(reply_args)
        # e.g. $3\r\nabc\r\n
        # 'bulk' is more complex because it could be part of multi-bulk
        when DOLLAR
          data_len = Integer(reply_args)
          if data_len == -1 # expect no data; return nil
            dispatch_response(nil)
          elsif @buffer.size >= data_len + 2 # buffer is full of expected data
            dispatch_response(@buffer.slice!(0, data_len))
            @buffer.slice!(0,2) # tossing \r\n
          else # buffer isn't full or nil
            raise ParserError
          end
        # e.g. :8
        when COLON
          dispatch_response(Integer(reply_args))
        # e.g. *2\r\n$1\r\na\r\n$1\r\nb\r\n
        when ASTERISK
          multibulk_count = Integer(reply_args)
          if multibulk_count == -1 || multibulk_count == 0
            dispatch_response([])
          else
            start_multibulk(multibulk_count)
          end
        # WAT?
        else
          error ProtocolError, "reply type not recognized: #{line.strip}"
        end
      end

      def dispatch_error(code)
        @sentinel_callbacks.shift
        error SentinelError, code
      end

      def dispatch_response(value)
        if @multibulk_n
          @multibulk_values << value
          @multibulk_n -= 1

          if @multibulk_n == 0
            value = @multibulk_values
            @multibulk_n = false
          else
            return
          end
        end

        callback = @sentinel_callbacks.shift
        if callback.kind_of?(Array) && callback.length == 2
          processor, blk = callback
          value = processor.call(value) if processor
          blk.call(value) if blk
        elsif callback.kind_of?(Array) && callback.length == 3
          processor, pipeline_count, blk = callback
          value = processor.call(value) if processor
          @values << value
          if pipeline_count > 1
            @sentinel_callbacks.unshift [processor, pipeline_count - 1, blk]
          else
            blk.call(@values) if blk
            @values = []
          end
        end
      end

      def start_multibulk(multibulk_count)
        @multibulk_n = multibulk_count
        @multibulk_values = []
      end

      def connected?
        @connected || false
      end

      def close
        @closing = true
        close_connection_after_writing
      end

      def unbind
        @logger.debug { "Disconnected" } if @logger
        if @closing
          @reconnecting = false
        elsif (@connected || @reconnecting) && @auto_reconnect
          @reconnect_callbacks[:before].call if @connected
          @reconnecting = true
          EM.add_timer(1) do
            @logger.debug { "Reconnecting to #{@host}:#{@port}" } if @logger
            reconnect @host, @port
          end
        elsif @connected
          error ConnectionError, 'connection closed'
        else
          error ConnectionError, 'unable to connect to sentinel server'
        end
        @connected = false
        @deferred_status = nil
      end

      private
        def get_size(string)
          string.respond_to?(:bytesize) ? string.bytesize : string.size
        end

    end
  end
end
