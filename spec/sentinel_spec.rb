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
      EM::Protocols::Redis.connect(:db => 14, :sentinels => sentinels) do |redis|
        redis.masters do |masters|
          expect(masters).to eq('poop')
          async_done
        end
      end
    end
  end
end
