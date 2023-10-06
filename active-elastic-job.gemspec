# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'active_elastic_job/version'

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'active_elastic_job'
  spec.version       = ActiveElasticJob.version
  spec.authors       = ['Tawan Sierek', 'Joey Paris']
  spec.email         = ['tawan@sierek.com', 'mail@joeyparis.me']
  spec.summary       = 'Active Elastic Job is a simple to use Active Job backend for Rails applications deployed on the Amazon Elastic Beanstalk platform.'
  spec.description   = 'Run background jobs / tasks of Rails applications deployed in Amazon Elastic Beanstalk environments. Active Elastic Job is an Active Job backend which is easy to setup. No need for customised container commands or other workarounds.'
  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/active-elastic-job/active-elastic-job'

  spec.files         = Dir.glob('lib/**/*') + [ 'active-elastic-job.gemspec' ]
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'aws-sdk-sqs', '~> 1'
  spec.add_dependency 'rails', '>= 5.2.6', '< 8'

  spec.add_development_dependency 'amazing_print', '~> 1.2'
  spec.add_development_dependency 'benchmark-ips', '~> 2.8'
  spec.add_development_dependency 'bootsnap', '~>1.9'
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'climate_control', '~> 0.2'
  spec.add_development_dependency 'dotenv', '~> 2.7'
  spec.add_development_dependency 'fuubar', '~> 2.5'
  spec.add_development_dependency 'rdoc', '~> 6.3'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'sprockets-rails', '~> 3.4'
  spec.add_development_dependency 'sqlite3', '~> 1.4'
end
