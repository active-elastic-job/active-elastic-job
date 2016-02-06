require 'spec_helper'
require 'digest'

class StubbedError < Aws::SQS::Errors::NonExistentQueue
  def initialize; end;
end

describe ActiveJob::QueueAdapters::ActiveElasticJobAdapter do
  subject(:adapter) { ActiveJob::QueueAdapters::ActiveElasticJobAdapter }

  let(:aws_sqs_client)  {
    double("aws_sqs_client")
  }
  let(:job) { Helpers::TestJob.new }
  let(:queue_url) { "http://some_url" }
  let(:queue_url_resp) { double("queue_url_resp") }
  let(:secret_key_base) { 's3krit' }
  let(:rails_app) { double("rails_app") }
  let(:resp) { double("resp") }
  let(:md5_body) { "body_digest" }
  let(:md5_attributes) { "attributes_digest" }
  let(:calculated_md5_body) { md5_body }
  let(:calculated_md5_attributes) { md5_attributes }

  before do
    allow(Aws::SQS::Client).to receive(:new) { aws_sqs_client }
    allow(Rails).to receive(:application) { rails_app }
    allow(rails_app).to receive(:secrets) { { secret_key_base: secret_key_base } }
    allow(aws_sqs_client).to receive(:get_queue_url) { queue_url_resp }
    allow(queue_url_resp).to receive(:queue_url) { queue_url }
    allow(aws_sqs_client).to receive(:send_message) { resp }
    allow(resp).to receive(:md5_of_message_body) { md5_body }
    allow(resp).to receive(:md5_of_message_attributes) { md5_attributes }
    allow(resp).to receive(:message_id) { "" }
    allow(adapter).to receive(:md5_of_message_body) { calculated_md5_body }
    allow(adapter).to receive(:md5_of_message_attributes) {
      calculated_md5_attributes
    }
  end

  describe ".enqueue" do
    it "selects the correct queue" do
      expected_args = { queue_name: job.queue_name.to_s }
      expect(aws_sqs_client).to receive(:get_queue_url).with(expected_args)

      adapter.enqueue job
    end

    it "caches the queue url" do
      expect(aws_sqs_client).to receive(:get_queue_url).exactly(0).times
      adapter.enqueue job
    end

    it "sends the serialized job as a message to an AWS SQS queue" do
      expect(aws_sqs_client).to receive(:send_message)

      adapter.enqueue job
    end

    describe "md5 digest verification" do
      let(:expected_error) {
        ActiveJob::QueueAdapters::ActiveElasticJobAdapter::MD5MismatchError
      }
      context "when md5 hash of message body does not match" do
        let(:calculated_md5_body) { "a different digest" }

        it "raises MD5MismatchError " do
          expect { adapter.enqueue(job) }.to raise_error(expected_error)
        end
      end

      context "when md5 hash of message attributes does not match" do
        let(:calculated_md5_attributes) { "a different digest" }

        it "raises MD5MismatchError " do
          expect { adapter.enqueue(job) }.to raise_error(expected_error)
        end
      end
    end

    context "when serialized job exeeds 256KB" do
      let(:exceeds_max_size) { 266 * 1024 }
      let(:arg) do
        arg = "x"
        exceeds_max_size.times do
          arg << "x"
        end
        arg
      end
      let(:job) { Helpers::TestJob.new(arg) }

      it "raises a SerializedJobTooBig error" do
        expected_error = ActiveJob::QueueAdapters::ActiveElasticJobAdapter::SerializedJobTooBig
        expect do
          adapter.enqueue(job)
        end.to raise_error(expected_error)
      end
    end

    context "when queue does not exist" do
      before do
        allow(adapter).to receive(:queue_url) { raise StubbedError }
      end

      it "raises NonExistentQueue error" do
        expected_error = ActiveJob::QueueAdapters::ActiveElasticJobAdapter::NonExistentQueue
        expect do
          adapter.enqueue(job)
        end.to raise_error(expected_error)
      end
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
