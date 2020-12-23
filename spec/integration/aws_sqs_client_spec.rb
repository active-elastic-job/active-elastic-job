require 'spec_helper'
require 'digest'

class TestJob < ActiveJob::Base
  queue_as :high_priority

  def perform(test_arg)
    test_arg
  end
end

describe Aws::SQS::Client, :deployed => true do
  subject(:aws_client)  { aws_sqs_client}

  it "is configured with valid credentials and region" do
    expect { aws_client.list_queues }.to_not raise_error
  end

  describe "message dispatching" do
    let(:queue_name) { "active_elastic_job_integration_testing" }
    let(:queue_url) do
      response = aws_client.create_queue(queue_name: queue_name)
      response.queue_url
    end
    let(:message_content) { JSON.dump(TestJob.new.serialize) }
    let(:message_attributes) {
      {
        "attribute" => {
          string_value: "Some value",
          data_type: "String"
        }
      }
    }
    let(:md5_digest_body) { Digest::MD5.hexdigest(message_content) }
    let(:md5_digest_attribute) { Digest::MD5.hexdigest(message_attribute) }

    describe "#send_message" do
      let(:md5_digest_verifier) {
        Class.new { extend ActiveElasticJob::MD5MessageDigestCalculation }
      }
      it "is successful" do
        response = aws_client.send_message(
          message_body: message_content,
          queue_url: queue_url,
          message_attributes: message_attributes
        )

        body_digest = md5_digest_verifier.md5_of_message_body(message_content)
        attributes_digest = md5_digest_verifier.md5_of_message_attributes(
          message_attributes)
        expect(response.md5_of_message_body).to match(body_digest)
        expect(response.md5_of_message_attributes).to match(attributes_digest)
      end

      context "when message size exeeds 256 KB" do
        let(:exceeds_max_size) { 266 * 1024 }
        let(:message_content) do
          body = "x" * exceeds_max_size
          JSON.dump(body)
        end

        it "raises an error" do
          expect(message_content.bytesize).to be >= exceeds_max_size
          expect do
            response = aws_client.send_message(
              message_body: message_content,
              queue_url: queue_url
            )
          end.to raise_error(Aws::SQS::Errors::InvalidParameterValue)
        end
      end
    end

    describe "#get_queue_url" do
      context "when queue does not exist" do
        let(:queue_name) { "not_existing_queue" }
        it "raises error" do
          expect do
            aws_client.get_queue_url(queue_name: queue_name)
          end.to raise_error(Aws::SQS::Errors::NonExistentQueue)
        end
      end
    end
  end
end
