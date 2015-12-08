require 'fileutils'
require 'aws-sdk'

module Helpers
  def deploy
    Dir.chdir(root_dir) do
      build_gem do
        unpack_gem_into_vendor_dir
        Dir.chdir("spec/integration/rails-app") do
          unless system("eb deploy")
            raise "Could not deploy application"
          end
        end
      end
    end
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
      system("mv rails_eb_job-#{gem_package_name} rails_eb_job-current")
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
