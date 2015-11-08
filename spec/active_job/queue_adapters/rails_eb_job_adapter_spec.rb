require 'spec_helper'

describe ActiveJob::QueueAdapters::RailsEbJobAdapter do
  let(:aws_client)  {
    Aws::SQS::Client.new(stub_responses: true, credentials: credentials)
  }

  before do
    aws_client.stub_responses(:get_queue_url, { queue_url: queue_url })
  end

  it "enqueues jobs to Amazon Simple Queue Service queues" do
    described_class.enqueue
  end
end
