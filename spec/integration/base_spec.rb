require 'spec_helper'
require 'tempfile'

describe "standard scenario" do
  before do
    s3 = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )

    s3_resource = Aws::S3::Resource.new(client: s3)
    s3_bucket = s3_resource.bucket('elasticbeanstalk-eu-west-1-103493342764')
    s3_object = s3_bucket.object(SecureRandom.hex)

    version = pack_version
    s3_object.upload_file(version)
  end

  it "enqueues and consumes a job successfully" do

  end

  def pack_version
File.expand_path('../Gemfile', File.dirname(__FILE__))
  end
end
