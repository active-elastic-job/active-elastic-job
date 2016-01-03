require 'bundler/setup'
Bundler.setup

require 'active_elastic_job'

require 'dotenv'
Dotenv.load

require File.expand_path('./helpers.rb', File.dirname(__FILE__))

RSpec.configure do |config|
  config.filter_run_excluding slow: true if ENV['SPEC_ALL'] != 'true'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include Helpers
end
