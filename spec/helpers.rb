require 'fileutils'
require 'aws-sdk'
require 'open-uri'
require 'active_job'
require 'climate_control'

module Helpers
  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT']
  WEB_ENV_NAME = ENV['WEB_ENV_NAME']
  WORKER_ENV_NAME = ENV['WORKER_ENV_NAME']

  class TestJob < ActiveJob::Base
    queue_as :high_priority

    def perform(test_arg)
      test_arg
    end
  end

  def aws_sqs_client
    Aws::SQS::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  class RailsApp
    def initialize
      @base_url = "http://#{WEB_ENV_HOST}:#{WEB_ENV_PORT}/"
    end

    def deploy
      build_gem
      begin
        unpack_gem_into_vendor_dir
        deploy_to_environment(WEB_ENV_NAME)
        deploy_to_environment(WORKER_ENV_NAME)
      ensure
        remove_gem
      end
    end

    def create_delete_job(random_string, delay = 0)
      resp = Net::HTTP.post_form(
      URI("#{@base_url}jobs"),
      { "random_string" => random_string, "delay" => delay })
      resp.value
      resp
    end

    def fetch_random_strings
      resp = JSON.load(
      open("#{@base_url}random_strings.json"))
      resp.collect { |a| a["random_string"] }
    end

    def delete_random_string(random_string)
      Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT) do |http|
        http.delete("/random_strings/#{random_string}")
      end
    end

    def create_random_string(random_string)
      resp = Net::HTTP.post_form(
      URI("#{@base_url}random_strings"),
      { "random_string" => random_string })
      resp.value
      resp
    end

    private

    def deploy_to_environment(env)
      Dir.chdir("#{root_dir}/spec/integration/rails-app") do
        unless system("eb deploy #{env}")
          raise "Could not deploy application to environment #{env}"
        end
      end
    end

    def build_gem
      sh(
        "gem build active-elastic-job.gemspec",
        "Could not build gem package!")
    end

    def remove_gem
      sh("rm -rf #{gem_package_name}.gem", "Could not remove gem")
    end

    def unpack_gem_into_vendor_dir
      target_dir = "#{root_dir}/spec/integration/rails-app/vendor/gems"
      unless File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end
      sh(
        "gem unpack #{gem_package_name}.gem --target #{target_dir}",
        "Could not unpack gem")
      sh(
        "rm -rf #{target_dir}/active_elastic_job-current",
        "Could not move gem")
      sh(
        "mv #{target_dir}/#{gem_package_name} #{target_dir}/active_elastic_job-current",
        "Could not move gem")
    end

    def gem_package_name
      "active_elastic_job-#{ActiveElasticJob::VERSION}"
    end

    def sh(command, error_msg)
      Dir.chdir(root_dir) do
        unless system(command)
          raise error_msg
        end
      end
    end

    def root_dir
      File.expand_path('../', File.dirname(__FILE__))
    end
  end
end

RSpec::Matchers.define :have_deleted do |expected|
  match do |actual|
    begin
      Timeout::timeout(5) do
        while(actual.fetch_random_strings.include?(expected)) do
          sleep 1
        end
      end
    rescue Timeout::Error
      return false
    end
    return true
  end
  failure_message do |actual|
    "Random string #{expected} has not been deleted within 5 seconds"
  end

  failure_message_when_negated do |actual|
    "Random string #{expected} has already been deleted"
  end
end
