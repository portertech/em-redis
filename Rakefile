require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => ['redis:test', 'spec']

namespace :redis do
  desc "Test em-redis against a live Redis"
  task :test do
    sh "bacon test/live_redis_protocol_spec.rb test/redis_commands_spec.rb test/redis_protocol_spec.rb"
  end
end
