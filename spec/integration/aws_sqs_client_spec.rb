require 'spec_helper'
require 'digest'

describe Aws::SQS::Client do
  subject(:aws_client)  {
    Aws::SQS::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  }

  it "is configured with valid credentials and region" do
    expect { aws_client.list_queues }.to_not raise_error
  end

  describe "message dispatching" do
    let(:queue_name) { "RailsEbJob-integration-testing" }
    let(:queue_url) do
      response = aws_client.create_queue(queue_name: queue_name)
      response.queue_url
    end
    let(:message_content) { "this is the content of the message" }
    let(:md5_digest) { Digest::MD5.hexdigest(message_content) }
    
    describe "#send_message" do
      it "is successful" do
        response = aws_client.send_message(
          message_body: message_content,
          queue_url: queue_url
        )

        expect(response.md5_of_message_body).to match(md5_digest)
      end
    end
  end
end
