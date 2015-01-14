require File.dirname(__FILE__) + '/helpers.rb'

require 'em-redis'

describe 'EM::Protocols::RedisSentinel' do
  before do
    @redis = EM::Protocols::Redis.connect :db => 14
    @redis.flushdb
  end

  it 'returns an EM connection object' do
    @redis.get('foo') do |foo|
      expect(foo).to eq('bar')
    end
  end
end
