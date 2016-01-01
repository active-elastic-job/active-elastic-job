require 'spec_helper'

describe ActiveJob::QueueAdapters::ActiveElasticJobAdapter do
  subject(:adapter) { ActiveJob::QueueAdapters::ActiveElasticJobAdapter }

  let(:aws_sqs_client)  {
    double("aws_sqs_client")
  }
  let(:job) { Helpers::TestJob.new }
  let(:queue_url) { "http://some_url" }
  let(:queue_url_resp) { double("queue_url_resp") }
  let(:secret_key_base) { 's3krit' }

  before do
    adapter.aws_sqs_client= aws_sqs_client
    allow(Rails.application).to receive(:secrets) { { secret_key_base: secret_key_base } }
  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expected_args = { queue_name: job.queue_name.to_s }
      expect(aws_sqs_client).to receive(:create_queue).with(expected_args)

      allow(aws_sqs_client).to receive(:create_queue) { queue_url_resp }
      allow(queue_url_resp).to receive(:queue_url) { queue_url }
      allow(aws_sqs_client).to receive(:send_message) { }
      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      allow(aws_sqs_client).to receive(:create_queue) { queue_url_resp }
      allow(queue_url_resp).to receive(:queue_url) { queue_url }
      expect(aws_sqs_client).to receive(:send_message)

      adapter.enqueue job
    end
  end
end
