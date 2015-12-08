require 'spec_helper'

describe "standard scenario" do
  let(:version_label) { "app-#{SecureRandom.hex[0..6]}" }
  let(:zip_file_name) { "#{version_label}.zip" }

  before do
    build_gem do
      zip_application(zip_file_name) do
        s3_key = upload_application(zip_file_name)
        create_application_version(s3_key, version_label)
        deploy(version_label)
      end
    end
  end

  it "enqueues and consumes a job successfully" do

  end
end
