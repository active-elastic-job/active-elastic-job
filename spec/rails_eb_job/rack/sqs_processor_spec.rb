require 'spec_helper'

describe RailsEbJob::Rack::SqsProcessor do
  let(:env) { double("env") }
  let(:app) { double("app") }

  subject(:sqs_processor) { RailsEbJob::Rack::SqsProcessor.new(app) }

  it "passes an ordinary request through" do
    expect(app).to receive(:call).with(env)
    sqs_processor.call(env)
  end

  context "when request is an SQS message" do
      let(:env) {
            
      }
  end
end
