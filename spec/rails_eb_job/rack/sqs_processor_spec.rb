require 'spec_helper'
require 'rack/mock'

describe RailsEbJob::Rack::SqsProcessor do
  let(:env) { Rack::MockRequest.env_for("http://example.com:8080/") }
  let(:app) { double("app") }
  let(:original_response) { double("original_response") }

  subject(:sqs_processor) { RailsEbJob::Rack::SqsProcessor.new(app) }

  it "passes an ordinary request through" do
    expect(app).to receive(:call).with(env).and_return(original_response)
    expect(sqs_processor.call(env)).to eq(original_response)
  end

  context "when request produced by EB SQS daemon" do
    let(:job) { Helpers::TestJob.new('test') }

    before do
      env['HTTP_USER_AGENT'] = 'aws-sqsd/1.1'
      env['rack.input'] = StringIO.new(JSON.dump(job.serialize))
    end

    it "intercepts request" do
      expect(app).not_to receive(:call).with(env)
      sqs_processor.call(env)
    end

    it "performs the job" do
      expect(sqs_processor.call(env)[0]).to eq('200')
    end

    context "when job execution fails" do
      let(:error_message)  { "intentional error" }

      before do
        allow(ActiveJob::Base).to receive(:execute).and_raise(error_message)
      end

      it "responds with a 500 error code" do
        response = sqs_processor.call(env)
        expect(response[0]).to eq('500')
        expect(response[2][0]).to eq(error_message)
      end
    end
  end
end
