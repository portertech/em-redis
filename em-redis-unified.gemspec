# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib', 'em-redis', 'constants')

Gem::Specification.new do |s|
  s.name        = 'em-redis-unified'
  s.version     = EMRedis::VERSION
  s.platform    = RUBY_PLATFORM =~ /java/ ? Gem::Platform::JAVA : Gem::Platform::RUBY
  s.authors     = ['Sean Porter', 'Justin Kolberg', 'Anthony Goddard']
  s.email       = ['portertech@gmail.com', 'amd.prophet@gmail.com', 'anthony@hw-ops.com']
  s.homepage    = 'https://github.com/portertech/em-redis-unified'
  s.summary     = 'An eventmachine-based implementation of the Redis protocol'
  s.description = "#{s.summary}. Based on the em-redis gem by Jonathan Broad."
  s.license     = 'MIT'
  s.has_rdoc    = false

  s.add_dependency('eventmachine', '>= 0.12.10')

  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('bacon')
  s.add_development_dependency('em-spec')

  s.files         = Dir.glob('{bin,lib}/**/*') + %w[em-redis-unified.gemspec README.md CHANGELOG.md MIT-LICENSE.txt]
  s.executables   = Dir.glob('bin/**/*').map { |file| File.basename(file) }
  s.require_paths = ['lib']
end
