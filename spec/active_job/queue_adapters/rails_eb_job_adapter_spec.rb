require 'spec_helper'
require 'active_job'

class TestJob < ActiveJob::Base
  queue_as :high_priority

  def perform(test_arg)
    test_arg
  end
end

describe ActiveJob::QueueAdapters::RailsEbJobAdapter do
  subject(:adapter) { ActiveJob::QueueAdapters::RailsEbJobAdapter }

  let(:aws_sqs_client)  {
    double("aws_sqs_client")
  }
  let(:job) { TestJob.new }
  let(:queue_url) { "http://some_url" }
  let(:queue_url_resp) { double("queue_url_resp") }

  before do
    adapter.aws_sqs_client= aws_sqs_client
  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expected_args = { queue_name: job.queue_name.to_s }
      expect(aws_sqs_client).to receive(:get_queue_url).with(expected_args)

      allow(aws_sqs_client).to receive(:get_queue_url) { queue_url_resp }
      allow(queue_url_resp).to receive(:queue_url) { queue_url }
      allow(aws_sqs_client).to receive(:send_message) { }
      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      allow(aws_sqs_client).to receive(:get_queue_url) { queue_url_resp }
      allow(queue_url_resp).to receive(:queue_url) { queue_url }
      expected_args = {
        queue_url: queue_url,
        message_body: JSON.dump(job.serialize)
      }
      expect(aws_sqs_client).to receive(:send_message).with(expected_args)

      adapter.enqueue job
    end
  end
end
