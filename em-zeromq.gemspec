# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-zeromq/version"

Gem::Specification.new do |s|
  s.name        = "em-zeromq"
  s.version     = EmZeromq::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrew Cholakian"]
  s.email       = ["andrew@andrewvc.com"]
  s.homepage    = "https://github.com/andrewvc/em-zeromq"
  s.summary     = %q{Low level event machine support for ZeroMQ}
  s.description = %q{Low level event machine support for ZeroMQ}
  s.rdoc_options = ["--main", "README.md"]

  s.rubyforge_project = "em-zeromq"

  s.add_dependency 'eventmachine', '>= 0.12.10'
  s.add_dependency 'ffi-rzmq', '>= 0.7.2'
  s.add_dependency 'ffi' if RUBY_PLATFORM != "java" && 
                            defined?(RUBY_ENGINE) && RUBY_ENGINE != 'rbx'
  s.add_development_dependency 'rspec', '>= 2.5.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

