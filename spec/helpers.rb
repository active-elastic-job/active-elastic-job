require 'fileutils'
require 'aws-sdk'

module Helpers
  APPLICATION_NAME = 'rails-eb-job-integration-testing'
  ENVIRONMENT_ID = 'e-7cgwewmdbe'

  def upload_application(file)
    client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )

    s3_resource = Aws::S3::Resource.new(client: client)
    s3_bucket = s3_resource.bucket(bucket)

    s3_key = "#{APPLICATION_NAME}/#{file}"
    s3_object = s3_bucket.object(s3_key)

    s3_object.upload_file(file, content_type: 'binary/octet-stream')
    s3_key
  end

  def deploy(version_label)
    eb_client.update_environment({
      application_name: APPLICATION_NAME,
      environment_id: ENVIRONMENT_ID,
      version_label: version_label
    })
  end

  def build_gem
    Dir.chdir(root_dir) do
      unless system("gem build rails-eb-job.gemspec")
        raise "Could not build gem package!"
      end
    end
    begin
      yield
    ensure
      Dir.chdir(root_dir) do
        FileUtils.rm(gem_package_name)
      end
    end
  end

  def unpack_gem_into_vendor_dir
    Dir.chdir(root_dir) do
      target_dir = "spec/integration/rails-app/vendor/gems"
      unless File.directory?(target_dir)
        FileUtils.mkdir_p(target_dir)
      end
      unless system("gem unpack #{gem_package_name} --target #{target_dir}")
        raise "Could not unpack gem"
      end
      Dir.chdir(target_dir) do
        system("mv rails_eb_job-#{RailsEbJob::VERSION} rails_eb_job-current")
      end
    end
  end

  def gem_package_name
    "rails_eb_job-#{RailsEbJob::VERSION}.gem"
  end

  def zip_application(file_name)
    Dir.chdir(root_dir) do
      Dir.chdir('spec/integration/rails-app') do
        unless system("zip -r #{root_dir}/#{file_name} .")
          raise "Could not archive application"
        end
      end
    end
    begin
      yield
    ensure
      Dir.chdir(root_dir) do
        FileUtils.rm(file_name)
      end
    end
  end

  def create_application_version(s3_key, version_label)
    resp = eb_client.create_application_version({
      application_name: APPLICATION_NAME,
      version_label: version_label,
      description: "test",
      source_bundle: {
        s3_bucket: bucket,
        s3_key: s3_key,
      },
      auto_create_application: true,
      process: true,
    })
  end

  private

  def eb_client
    Aws::ElasticBeanstalk::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def root_dir
    File.expand_path('../', File.dirname(__FILE__))
  end

  def bucket
    eb_client.create_storage_location.s3_bucket
  end
end
