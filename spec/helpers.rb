require 'rspec'
require 'eventmachine'
require 'em-redis'

module Helpers
  def timer(delay, &block)
    periodic_timer = EM::PeriodicTimer.new(delay) do
      block.call
      periodic_timer.cancel
    end
  end

  def async_wrapper(&block)
    EM::run do
      timer(10) do
        raise 'test timed out'
      end
      block.call
    end
  end

  def async_done
    EM::stop_event_loop
  end

  def redis_async_wrapper(&block)
    async_wrapper do
      EM::Protocols::Redis.connect(:db => 14) do |redis|
        redis.flushdb do
          block.call(redis)
        end
      end
    end
  end
end
