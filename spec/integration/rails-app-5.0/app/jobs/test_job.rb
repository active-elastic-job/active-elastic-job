require 'net/http'

class TestJob < ActiveJob::Base
  queue_as :active_elastic_job_integration_testing

  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT']

  def perform(random_string)
    Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT, use_ssl: false, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
      request = Net::HTTP::Delete.new "/random_strings/#{random_string}"
      https.request request
    end
  end
end
