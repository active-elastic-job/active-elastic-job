# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'rails_eb_job'
  spec.version       = '0.1.0'
  spec.authors       = ['Tawan Sierek']
  spec.email         = ['tawan@sierek.com']
  spec.description = spec.summary = %q()
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'rails', '~> 4.2'
  spec.add_dependency 'aws-sdk-core', '~> 2'
end
