# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'raw2swagger/version'

Gem::Specification.new do |gem|
  gem.name          = "raw2swagger"
  
  gem.authors       = ["Josep M. Pujol"]
  gem.email         = 'josep@3scale.net'

  gem.description   = %q{}
  gem.summary       = %q{}

  gem.homepage      = ""

  #gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.version       = Raw2Swagger::VERSION
  
  gem.add_dependency 'json'
  gem.add_dependency 'rake'
  gem.add_dependency 'thin'
  gem.add_dependency 'rack',		'1.5.2'
  gem.add_dependency 'rack-test'
end
