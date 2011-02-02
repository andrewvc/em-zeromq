# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-zeromq}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrew Cholakian"]
  s.date = %q{2011-02-01}
  s.default_executable = %q{em-zeromq}
  s.description = %q{Low level event machine support for ZeroMQ}
  s.email = %q{andrew@andrewvc.com}
  s.executables = ["em-zeromq"]
  s.extra_rdoc_files = ["History.txt", "bin/em-zeromq", "lib/em-zeromq/.connection.rb.swp", "version.txt"]
  s.files = [".Rakefile.swo", ".bnsignore", "History.txt", "README.md", "Rakefile", "bin/em-zeromq", "example/simple.rb", "lib/em-zeromq.rb", "lib/em-zeromq/.connection.rb.swp", "lib/em-zeromq/connection.rb", "lib/em-zeromq/zeromq.rb", "spec/.pub_sub_spec.rb.swp", "spec/pub_sub_spec.rb", "spec/push_pull_spec.rb", "spec/spec_helper.rb", "test/test_em-zeromq.rb", "version.txt"]
  s.homepage = %q{https://github.com/andrewvc/em-zeromq}
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{em-zeromq}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Low level event machine support for ZeroMQ}
  s.test_files = ["test/test_em-zeromq.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bones>, [">= 3.5.4"])
    else
      s.add_dependency(%q<bones>, [">= 3.5.4"])
    end
  else
    s.add_dependency(%q<bones>, [">= 3.5.4"])
  end
end
