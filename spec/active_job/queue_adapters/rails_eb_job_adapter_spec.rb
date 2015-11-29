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

  let(:aws_client)  {
    double("aws_client")
  }
  let(:job) { TestJob.new }
  let(:queue_url) { "http://some_url" }

  before do
    adapter.aws_client = aws_client
  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expected_args = { queue_name: job.queue_name.to_s }
      expect(aws_client).to receive(:get_queue_url).with(expected_args)

      allow(aws_client).to receive(:send_message) { }
      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      allow(aws_client).to receive(:get_queue_url) { queue_url }
      expected_args = {
        queue_url: queue_url,
        message_body: job.serialize
      }
      expect(aws_client).to receive(:send_message).with(expected_args)

      adapter.enqueue job
    end
  end
end
