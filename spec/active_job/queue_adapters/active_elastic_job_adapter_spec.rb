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
    allow(aws_sqs_client).to receive(:create_queue) { queue_url_resp }
    allow(queue_url_resp).to receive(:queue_url) { queue_url }
    allow(aws_sqs_client).to receive(:send_message) { }
  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expected_args = { queue_name: job.queue_name.to_s }
      expect(aws_sqs_client).to receive(:create_queue).with(expected_args)

      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      expect(aws_sqs_client).to receive(:send_message)

      adapter.enqueue job
    end
  end

  describe ".enqueue_at" do
    let(:delay) { 2.minutes }
    let(:timestamp) { Time.now + delay }

    it "sends the seralized job as a message with a delay to match given timestamp" do
      expect(aws_sqs_client).to receive(:send_message).with(hash_including(
        delay_seconds: delay
      ))
      adapter.enqueue_at(job, timestamp)
    end

    context "when scheduled timestamp exceeds 15 minutes" do
      let(:delay) { 16.minutes }

      it "raises a RangeError" do
        expect { adapter.enqueue_at(job, timestamp) }.to raise_error(RangeError)
      end
    end
  end
end
