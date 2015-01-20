require File.dirname(__FILE__) + '/helpers.rb'

require 'em-redis'

describe 'EM::Protocols::RedisSentinel' do
  include Helpers

  let(:sentinels) do
    [
      {
        :host => '127.0.0.1',
        :port => 26379
      },
      {
        :host => '127.0.0.1',
        :port => 26380
      },
      {
        :host => '127.0.0.1',
        :port => 26381
      }
    ]
  end

  let(:sentinels_hash) do
    {
      :host => '127.0.0.1',
      :port => 26379
    }
  end

  let(:sentinels_strings) do
    [
      "redis://127.0.0.1:26379",
      "redis://127.0.0.1:26380",
      "redis://127.0.0.1:26381"
    ]
  end

  it 'successfully connects to redis' do
    async_wrapper do
      EM::Protocols::Redis.connect(:db => 14) do |redis|
        redis.flushdb do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it 'successfully connects to redis with sentinels' do
    async_wrapper do
      EM::Protocols::Redis.connect(:sentinels => sentinels) do |redis|
        redis.flushdb do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it 'successfully connects if sentinels are defined as a string' do
    async_wrapper do
      EM::Protocols::Redis.connect(:sentinels => sentinels_strings) do |redis|
        redis.flushdb do
          expect(redis.connected?).to eq(true)
          async_done
        end
      end
    end
  end

  it 'unsuccessfully connects if sentinels are not in an array' do
    async_wrapper do
      begin
        EM::Protocols::Redis.connect(:sentinels => sentinels_hash) do |redis|
        end
      rescue TypeError => e
        async_done
      end
    end
  end
end
