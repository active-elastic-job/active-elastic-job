require 'spec_helper'
require 'active_job'

class TestJob < ActiveJob::Base
  def perform(test_arg)
    test_arg
  end
end

describe ActiveJob::QueueAdapters::RailsEbJobAdapter do
  subject(:adapter) { ActiveJob::QueueAdapters::RailsEbJobAdapter }

  let(:aws_client)  {
    Aws::SQS::Client.new(stub_responses: true)
  }
  let(:job) { TestJob.new }

  before do
    adapter.aws_client = aws_client
  end

  describe ".enqueue" do
    it "sends the serialized job as a message to an AWS SQS queue" do

    end
  end
end
