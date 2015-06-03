# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'egi/fedcloud/vmhound/version'

Gem::Specification.new do |gem|
  gem.name          = "egi-fedcloud-vmhound"
  gem.version       = Egi::Fedcloud::Vmhound::VERSION
  gem.authors       = ["Boris Parak"]
  gem.email         = ['parak@cesnet.cz']
  gem.description   = %q{A proof-of-concept utility for locating VM instances in EGI Federated Cloud}
  gem.summary       = %q{A proof-of-concept utility for locating VM instances in EGI Federated Cloud}
  gem.homepage      = 'https://github.com/arax/egi-fedcloud-vmhound'
  gem.license       = 'Apache License, Version 2.0'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport', '~> 4.0', '>= 4.0.0'
  gem.add_dependency 'settingslogic', '~> 2.0', '>= 2.0.9'
  gem.add_dependency 'thor', '~> 0.19', '>= 0.19.1'
  gem.add_dependency 'opennebula', '~> 4.10', '>= 4.10.2'
  gem.add_dependency 'terminal-table', '~> 1.4', '>= 1.4.5'
  gem.add_dependency 'ox', '~> 2.2', '>= 2.2.0'

  gem.add_development_dependency 'bundler', '~> 1.6'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec', '~> 3.0.0'
  gem.add_development_dependency 'simplecov', '~> 0.9.0'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2.4'

  gem.required_ruby_version = ">= 1.9.3"
end
