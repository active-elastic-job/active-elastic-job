require 'spec_helper'
require 'rack/mock'
require 'rails'

describe ActiveElasticJob::Rack::SqsMessageConsumer do
  let(:env) { Rack::MockRequest.env_for("http://example.com:8080/") }
  let(:app) { double("app") }
  let(:original_response) { double("original_response") }
  let(:secret_key_base) { 's3krit' }
  let(:rails_app) { double("rails_app") }

  before do
    allow(Rails).to receive(:application) { rails_app }
    allow(rails_app).to receive(:secrets) { { secret_key_base: secret_key_base } }
  end

  subject(:sqs_message_consumer) { ActiveElasticJob::Rack::SqsMessageConsumer.new(app) }

  it "passes an ordinary request through" do
    expect(app).to receive(:call).with(env).and_return(original_response)
    expect(sqs_message_consumer.call(env)).to eq(original_response)
  end

  context "when user agent matches" do
    let(:job) { Helpers::TestJob.new('test') }

    before do
      verifier = ActiveElasticJob::MessageVerifier.new(secret_key_base)
      message_body = JSON.dump(job.serialize)
      env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = verifier.generate_digest(message_body)
      env['HTTP_X_AWS_SQSD_ATTR_ORIGIN'] = origin_attribute
      env['HTTP_USER_AGENT'] = 'aws-sqsd/1.1'
      env['rack.input'] = StringIO.new(message_body)
    end

    context "when origin is not set" do
      let(:origin_attribute) { nil }

      it "passes request through" do
        expect(app).to receive(:call).with(env).and_return(original_response)
        expect(sqs_message_consumer.call(env)).to eq(original_response)
      end
    end

    context "when origin is not Active Elastic Job" do
      let(:origin_attribute) { "some thing else" }

      it "passes request through" do
        expect(app).to receive(:call).with(env).and_return(original_response)
        expect(sqs_message_consumer.call(env)).to eq(original_response)
      end
    end

    context "when origin is Active Elastic Job" do
      let(:origin_attribute) { "AEJ" }

      it "intercepts request" do
        expect(app).not_to receive(:call).with(env)
        sqs_message_consumer.call(env)
      end

      it "performs the job" do
        expect(sqs_message_consumer.call(env)[0]).to eq('200')
      end

      context "when digest is ommited" do
        before do
          env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = nil
        end

        it "responds with a 403 status code" do
          response = sqs_message_consumer.call(env)
          expect(response[0]).to eq('403')
        end
      end

      context "when digest is forged" do
        before do
          env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = 'forged'
        end

        it "responds with a 403 status code" do
          response = sqs_message_consumer.call(env)
          expect(response[0]).to eq('403')
        end
      end

      context "when job execution fails" do
        let(:error_message)  { "intentional error" }

        before do
          allow(ActiveJob::Base).to receive(:execute).and_raise(error_message)
        end

        it "responds with a 500 error code" do
          response = sqs_message_consumer.call(env)
          expect(response[0]).to eq('500')
          expect(response[2][0]).to eq(error_message)
        end
      end
    end
  end
end
