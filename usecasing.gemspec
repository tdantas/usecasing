# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'usecasing/version'

Gem::Specification.new do |gem|
  gem.name          = "usecasing"
  gem.version       = Usecasing::VERSION
  gem.authors       = ["Thiago Dantas"]
  gem.email         = ["thiago.teixeira.dantas@gmail.com"]
  gem.description   = %q{UseCase Driven approach to your code}
  gem.summary       = %q{UseCase Driven Approach}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]


  #development dependecy
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "mocha"
  
end
