require 'fileutils'
require 'aws-sdk-sqs'
require 'open-uri'
require 'active_job'
require 'active_job/queue_adapters'
require 'climate_control'
require 'amazing_print'

module Helpers
  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT'].to_i
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

  def localstack_aws_sqs_client
    Aws::SQS::Client.new(
      access_key_id: "SQS",
      secret_access_key: "SQS_QUEUE",
      region: ENV['AWS_REGION'],
      endpoint: "http://localhost:4566"
    )
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  class RailsApp
    def initialize(version = "5.2")
      @version = version
      @base_url = "https://#{WEB_ENV_HOST}/"
    end

    def initialize_eb_application
      run_in_rails_app_root_dir do
        unless system("eb init active_elastic_job -p ruby --region #{ENV['AWS_REGION']}")
          raise "Could not initialize eb application"
        end
      end
    end

    def launch_eb_web_environment
      run_in_rails_app_root_dir do
        unless system(
            <<~SH
              eb create web-env -c active-elastic-job \
              --elb-type application \
              --vpc.elbpublic \
              --envvars SECRET_KEY_BASE=secret,AWS_REGION=#{ENV['AWS_REGION']}
            SH
          )
          raise "Could not launch eb web environment"
        end
      end
    end

    def launch_eb_worker_environment
      run_in_rails_app_root_dir do
        unless system(
            <<~SH
              eb create worker-env -t worker \
              --single \
              --envvars SECRET_KEY_BASE=secret,AWS_REGION=#{ENV['AWS_REGION']},WEB_ENV_HOST=active-elastic-job.#{ENV['AWS_REGION']}.elasticbeanstalk.com,WEB_ENV_PORT=443,PROCESS_ACTIVE_ELASTIC_JOBS=true
            SH
          )
          raise "Could not launch eb worker environment"
        end
      end
    end

    def terminate_eb_environments
      # env = WEB_ENV_NAME
      # run_in_rails_app_root_dir do
      #   unless system("eb terminate --force #{env}")
      #     raise "Could not terminate environment #{env}"
      #   end
      # end
      # env = WORKER_ENV_NAME
      # run_in_rails_app_root_dir do
      #   unless system("eb terminate --force #{env}")
      #     raise "Could not terminate environment #{env}"
      #   end
      # end
    end

    def deploy
      use_gem do
        initialize_eb_application
        launch_eb_web_environment
        launch_eb_worker_environment
        deploy_to_environment(WEB_ENV_NAME)
        deploy_to_environment(WORKER_ENV_NAME)
      end
    end

    def create_delete_job(random_string, delay = 0)
      Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
        req = Net::HTTP::Post.new("/jobs")
        req.set_form_data("random_string" => random_string, "delay" => delay)
        resp = https.request req

        raise "Could not delete job. HTTP Request failed #{resp.code}" if resp.code != "200"
      end
    end

    def fetch_random_strings
      resp = nil
      Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
        request = Net::HTTP::Get.new("/random_strings.json")
        resp = https.request request
      end
      resp = JSON.load(
        resp.body
      )
      resp.collect { |a| a["random_string"] }
    end

    def create_random_string(random_string)
      Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
        req = Net::HTTP::Post.new("/random_strings.json", 'Content-Type' => 'application/json')
        req.body = {"random_string" => {"random_string" => random_string}}.to_json
        resp = https.request req
        raise "Could not create random string. HTTP Request got #{resp.code} response" if resp.code != "200"
      end
    end

    def run_in_rails_app_root_dir(&block)
      use_gem do
        Dir.chdir("#{root_dir}/spec/integration/rails-app-#{@version}") do
          yield
        end
      end
    end

    private

    def deploy_to_environment(env)
      run_in_rails_app_root_dir do
        unless system("eb deploy #{env}")
          raise "Could not deploy application to environment #{env}"
        end
      end
    end

    def use_gem(&block)
      build_gem
      unpack_gem_into_vendor_dir(&block)
      remove_gem
    end

    def build_gem
      sh(
        "gem build active-elastic-job.gemspec",
        "Could not build gem package!")
    end

    def remove_gem
      sh("rm -rf #{gem_package_name}.gem", "Could not remove gem")
    end

    def unpack_gem_into_vendor_dir(&block)
      target_dir = "#{root_dir}/spec/integration/rails-app-#{@version}/vendor/gems"
      unless File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end
      sh(
        "gem unpack #{gem_package_name}.gem --target #{target_dir}",
        "Could not unpack gem")
      sh(
        "mv #{target_dir}/#{gem_package_name} #{target_dir}/active_elastic_job-current",
        "Could not move gem")
      begin
        yield
      ensure
        sh(
          "rm -rf #{target_dir}/active_elastic_job-current",
          "Could not remove gem")
      end
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
