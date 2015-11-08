require 'bundler/setup'
Bundler.setup

require 'pry-byebug'
require 'rails_eb_job'
require 'dotenv'
Dotenv.load

RSpec.configure do |config|
  config.before do
  end
end
