# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)
require "em-redis"

Gem::Specification.new do |spec|
  spec.name          = "em-redis-unified"
  spec.version       = EMRedis::VERSION
  spec.authors       = ["Jonathan Broad", "Eugene Pimenov", "Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = "An eventmachine-based implementation of the Redis protocol"
  spec.description   = "An eventmachine-based implementation of the Redis protocol"
  spec.homepage      = "https://github.com/portertech/em-redis"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("eventmachine", ">=0.12.10")

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "em-spec"
  spec.add_development_dependency "bacon"
end
