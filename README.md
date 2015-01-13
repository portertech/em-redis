## Description:

An [EventMachine](http://rubyeventmachine.com/) based library for interacting
with the very cool [Redis](http://code.google.com/p/redis/) data store by
Salvatore 'antirez' Sanfilippo. Modeled after eventmachine's implementation of
the memcached protocol, and influenced by Ezra Zygmuntowicz's
[redis-rb](http://github.com/ezmobius/redis-rb/tree/master) library
(distributed as part of Redis). Based on the
[em-redis](https://github.com/madsimian/em-redis) gem by Jonathan Broad.

This library is only useful when used as part of an application that relies on
Event Machine's event loop.  It implements an EM-based client protocol, which
leverages the non-blocking nature of the EM interface to achieve significant
parallelization without threads.

## Features/Problems:

Implements most Redis commands (see [the list of available commands
here](http://code.google.com/p/redis/wiki/CommandReference) with the notable
exception of MONITOR.

## Synopsis:

Like any Deferrable eventmachine-based protocol implementation, using EM-Redis
involves making calls and passing blocks that serve as callbacks when the call
returns.


    require 'em-redis'

    EM.run do
      redis = EM::Protocols::Redis.connect
      redis.errback do |err|
        puts err.inspect
        puts "Error code: #{err.code}" if err.code
      end
      redis.set "a", "foo" do |response|
        redis.get "a" do |response|
          puts response
        end
      end
      # We get pipelining for free
      redis.set("b", "bar")
      redis.get("a") do |response|
        puts response # will be foo
      end
    end

To run tests on a Redis server (currently compatible with 1.3)

    rake

Because the EM::Protocol::Memcached code used Bacon for testing, test code is
currently in the form of bacon specs.

## Requirements:

*   Redis ([download](http://code.google.com/p/redis/downloads/list))


## Install:

    sudo gem install em-redis-unified

## License:

em-redis-unified is released under the [MIT license](https://raw.github.com/portertech/em-redis/unified/MIT-LICENSE.txt).
