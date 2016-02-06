require 'bundler/setup'
Bundler.setup

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.0.0')
  require 'byebug'
end

require 'active_elastic_job'

require 'dotenv'
Dotenv.load

require File.expand_path('./helpers.rb', File.dirname(__FILE__))

RSpec.configure do |config|
  config.filter_run_excluding slow: true if ENV['EXCEPT_SLOW'] == 'true'
  config.filter_run_excluding deployed: true if ENV['EXCEPT_DEPLOYED'] == 'true'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include Helpers
end
