require 'net/http'

class TestJob < ActiveJob::Base
  queue_as :active_elastic_job_integration_testing

  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT']

  def perform(random_string)
    Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT) do |http|
      http.delete("/random_strings/#{random_string}")
    end
  end
end
