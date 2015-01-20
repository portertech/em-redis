require_relative 'redis_protocol'

module EventMachine
  module Protocols
    module RedisSentinel
      module InstanceMethods
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
      end

      ##
      # errors
      #########################

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
        def included(klass)
          klass.class_eval do
            include EventMachine::Protocols::Redis
            include EventMachine::Protocols::RedisSentinel::InstanceMethods
          end
        end

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
                    redis_connection = EM.connect(master[0], master[1], self)
                    callback.call(redis_connection) if callback
                  end
                end
                true
              else
                raise TypeError.new('a sentinel must be a Hash')
              end
            end
          else
            raise TypeError.new('sentinels must be an Array')
          end
        end
      end
    end
  end
end

