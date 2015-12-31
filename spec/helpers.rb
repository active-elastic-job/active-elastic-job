require 'fileutils'
require 'aws-sdk'
require 'open-uri'
require 'active_job'

module Helpers
  WEB_ENV_HOST = ENV['WEB_ENV_HOST']
  WEB_ENV_PORT = ENV['WEB_ENV_PORT']

  class TestJob < ActiveJob::Base
    queue_as :high_priority

    def perform(test_arg)
      test_arg
    end
  end

  def deploy
    Dir.chdir(root_dir) do
      build_gem do
        unpack_gem_into_vendor_dir
        Dir.chdir("spec/integration/rails-app") do
          [ 'web-env', 'worker-env' ].each do |env|
            unless system("eb deploy #{env}")
              raise "Could not deploy application to environment #{env}"
            end
          end
        end
      end
    end
  end

  def aws_sqs_client
    Aws::SQS::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def create_job(random_string)
    resp = Net::HTTP.post_form URI("http://#{WEB_ENV_HOST}:#{WEB_ENV_PORT}/jobs"),
    { "random_string" => random_string }
    resp.value
    resp
  end

  def fetch_random_strings
    resp = JSON.load(open("http://#{WEB_ENV_HOST}:#{WEB_ENV_PORT}/random_strings.json"))
    resp.collect { |a| a["random_string"] }
  end

  def delete_random_string(random_string)
    Net::HTTP.start(WEB_ENV_HOST, WEB_ENV_PORT) do |http|
      http.delete("/random_strings/#{random_string}")
    end
  end

  def create_random_string(random_string)
    resp = Net::HTTP.post_form URI("http://#{WEB_ENV_HOST}:#{WEB_ENV_PORT}/random_strings"),
    { "random_string" => random_string }
    resp.value
    resp
  end

  private

  def build_gem
    unless system("gem build rails-eb-job.gemspec")
      raise "Could not build gem package!"
    end
    begin
      yield
    ensure
      FileUtils.rm("#{gem_package_name}.gem")
    end
  end

  def unpack_gem_into_vendor_dir
    target_dir = "spec/integration/rails-app/vendor/gems"
    unless File.directory?(target_dir)
      FileUtils.mkdir_p(target_dir)
    end
    unless system("gem unpack #{gem_package_name}.gem --target #{target_dir}")
      raise "Could not unpack gem"
    end
    Dir.chdir(target_dir) do
      unless system("rm -rf rails_eb_job-current") && system("mv #{gem_package_name} rails_eb_job-current")
        raise "Could not move gem"
      end
    end
  end

  def gem_package_name
    "rails_eb_job-#{RailsEbJob::VERSION}"
  end

  def root_dir
    File.expand_path('../', File.dirname(__FILE__))
  end

  def bucket
    eb_client.create_storage_location.s3_bucket
  end
end
