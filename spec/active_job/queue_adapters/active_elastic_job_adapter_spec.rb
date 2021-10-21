require 'spec_helper'
require 'digest'

class StubbedError < Aws::SQS::Errors::NonExistentQueue
  def initialize; end;
end

describe ActiveJob::QueueAdapters::ActiveElasticJobAdapter do
  subject(:adapter) { ActiveJob::QueueAdapters::ActiveElasticJobAdapter }

  let(:job) { Helpers::TestJob.new }
  let(:secret_key_base) { "s3krit" }
  let(:aws_credentials) { 
    Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  }

  let(:aws_sqs_client) { double("aws_sqs_client") }

  before do
    allow(adapter).to receive(:secret_key_base) { secret_key_base }
    allow(adapter).to receive(:aws_sqs_client_credentials) { aws_credentials }
    allow(adapter).to receive(:aws_region) { 'us-east-1' }
    allow(adapter).to receive(:aws_sqs_client) { aws_sqs_client }
    allow(aws_sqs_client).to receive(:get_queue_url) {
      double("queue_url_resp", :queue_url => "http://queue_url")
    }
    allow(aws_sqs_client).to receive(:send_message) {
      double("send_message_response", :md5_of_message_body => "some hash", :message_id => "some string")
    }

  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expect(adapter).to receive(:queue_url).with(job.queue_name).and_return(
        aws_sqs_client.get_queue_url(queue_name: job.queue_name.to_s).queue_url)

      adapter.enqueue job
    end

    it "caches the queue url" do
      adapter.enqueue job
      expect(aws_sqs_client).to receive(:get_queue_url).exactly(0).times
      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      expect(adapter.send(:aws_sqs_client)).to(receive(:send_message))
      allow(adapter).to receive(:verify_md5_digests!)
      adapter.enqueue job
    end

    context "when aws client does not verify md5 diggests" do
      before do
        allow(adapter).to receive(:aws_client_verifies_md5_digests?) { false }
      end

      it "verifies returned md5 digests" do
        expect(adapter).to receive(:verify_md5_digests!)
        adapter.enqueue job
      end
    end

    context "when serialized job exeeds 256KB" do
      let(:exceeds_max_size) { 266 * 1024 }
      let(:arg) { "." * exceeds_max_size }
      let(:job) { Helpers::TestJob.new(arg) }

      it "raises a SerializedJobTooBig error" do
        expect do
          adapter.enqueue(job)
        end.to raise_error(
          ActiveJob::QueueAdapters::ActiveElasticJobAdapter::SerializedJobTooBig)
      end
    end

    context "when queue does not exist" do
      before do
        allow(adapter).to receive(:queue_url) { raise StubbedError }
      end

      it "raises NonExistentQueue error" do
        expect do
          adapter.enqueue(job)
        end.to raise_error(
          ActiveJob::QueueAdapters::ActiveElasticJobAdapter::NonExistentQueue)
      end
    end

    context "when the underlying queue is a FIFO queue" do
      let(:job_id) { "be8767f8-2b34-4179-9843-47024ac12703" }

      before do
        allow(job).to receive(:queue_name) { "high_priority.fifo" }
        allow(job).to receive(:job_id) { job_id }
      end

      it "sets the required attributes" do
        client = adapter.send(:aws_sqs_client)

        expect(client).to receive(:send_message).with(hash_including(
          message_group_id: "Helpers::TestJob",
          message_deduplication_id: job_id
        ))

        adapter.enqueue(job)
      end
    end
  end

  describe ".enqueue_at" do
    let(:delay) { 2.minutes }
    let(:timestamp) { Time.now + delay }

    it "sends the job as a message with a delay to match given timestamp" do
      client = adapter.send(:aws_sqs_client)
      allow(adapter).to receive(:verify_md5_digests!)
      expect(client).to receive(:send_message).with(hash_including(
        delay_seconds: delay
      ))
      adapter.enqueue_at(job, timestamp)
    end

    context "when scheduled timestamp exceeds 15 minutes" do
      let(:delay) { 16.minutes }

      it "raises a DelayTooLong" do
        expect { adapter.enqueue_at(job, timestamp) }
          .to raise_error(ActiveJob::QueueAdapters::ActiveElasticJobAdapter::DelayTooLong)
      end
    end
  end
end
