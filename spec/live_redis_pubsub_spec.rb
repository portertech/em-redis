require File.expand_path(File.dirname(__FILE__) + "/test_helper.rb")

EM.describe EM::Protocols::Redis, "connected to an empty db" do

  before do
    @s = EM::Protocols::Redis.connect(:db => 14)
    @p = EM::Protocols::Redis.connect(:db => 14)
  end

  should "be able to publish a message to a channel" do
    @p.flushdb do
     @p.publish("foo", "test") do |r|
        r.should == 0
        done
      end
    end
  end

  should "be able to subscribe to a channel and then unsubscribe" do
    @s.flushdb do
      @s.subscribe("foo", Proc.new {}) do |type, channel, subscribers|
        type.should == "subscribe"
        channel.should == "foo"
        subscribers.should == 1
        @s.unsubscribe do
          done
        end
      end
    end
  end

  should "be able to subscribe to a channel and publish a message to it" do
    @s.flushdb do
      callback = Proc.new do |type, channel, message|
        type.should == "message"
        channel.should == "foo"
        message.should == "test"
        done
      end
      @s.subscribe("foo", callback) do |type, channel, subscribers|
        type.should == "subscribe"
        channel.should == "foo"
        subscribers.should == 1
        @p.publish("foo", "test") do |r|
          r.should == 1
        end
      end
    end
  end
end
