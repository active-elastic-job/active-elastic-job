# encoding: UTF-8

require 'spec_helper'
require 'securerandom'

describe ActiveElasticJob::MD5MessageDigestCalculation, :deployed => true do
  let(:queue_name) { "ActiveElasticJob-integration-testing" }
  let(:queue_url) {
    aws_sqs_client.create_queue(queue_name: queue_name).queue_url
  }
  let(:base_class) {
    Class.new { extend ActiveElasticJob::MD5MessageDigestCalculation }
  }

  describe "#md5_of_message_body" do
    let(:message_body) { JSON.dump(Helpers::TestJob.new.serialize) }
    let(:expected_hash) {
      aws_sqs_client.send_message(
        message_body: message_body,
        queue_url: queue_url
      ).md5_of_message_body
    }
    subject { base_class.md5_of_message_body(message_body) }

    it { is_expected.to eq(expected_hash) }
  end

  describe "#md5_of_message_attributes" do
    let(:message_attributes) {
      {
        "ccc" => {
          string_value: "test",
          data_type: "String"
        },
        aaa: {
          binary_value: SecureRandom.random_bytes(12),
          data_type: "Binary"
        },
        zzz: {
          data_type: "Number",
          string_value: "0230.01"
        },
        "öther_encodings" => {
          data_type: "String",
          string_value: "Tüst".encode!("ISO-8859-1")
        }
      }
    }

    let(:expected_hash) {
      aws_sqs_client.send_message(
        message_body: "test",
        queue_url: queue_url,
        message_attributes: message_attributes
      ).md5_of_message_attributes
    }

    subject { base_class.md5_of_message_attributes(message_attributes) }

    it { is_expected.to eq(expected_hash) }
  end
end
