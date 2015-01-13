require 'bundler/gem_tasks'

begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'em-redis'

task :default => ['redis:test']

namespace :redis do
  desc "Test em-redis against a live Redis"
  task :test do
    sh "bacon spec/live_redis_protocol_spec.rb spec/redis_commands_spec.rb spec/redis_protocol_spec.rb"
  end
end
