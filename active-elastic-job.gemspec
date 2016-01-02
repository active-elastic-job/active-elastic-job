# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'active_elastic_job/version'

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'active_elastic_job'
  spec.version       = ActiveElasticJob::VERSION
  spec.authors       = ['Tawan Sierek']
  spec.email         = ['tawan@sierek.com']
  spec.description = spec.summary = %q()
  spec.license       = 'MIT'

  spec.files         = Dir.glob('lib/**/*') + [ 'active-elastic-job.gemspec' ]
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'rails', '~> 4.2'
  spec.add_development_dependency 'rdoc'
  spec.add_dependency 'aws-sdk', '~> 2'
end
