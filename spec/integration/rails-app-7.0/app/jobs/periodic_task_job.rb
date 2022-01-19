require 'net/http'

class PeriodicTaskJob < ActiveJob::Base
  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT']

  def perform
    Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
      request = Net::HTTP::Delete.new "/random_strings/from_periodic_task"
      https.request request
    end
  end
end
