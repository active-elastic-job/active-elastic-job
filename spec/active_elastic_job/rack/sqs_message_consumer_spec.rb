require 'spec_helper'
require 'rack/mock'
require 'rails'

describe ActiveElasticJob::Rack::SqsMessageConsumer do
  let(:env) { Rack::MockRequest.env_for("http://example.com:8080/") }
  let(:app) { double("app") }
  let(:original_response) { double("original_response") }
  let(:secret_key_base) { 's3krit' }
  let(:rails_app) { double("rails_app") }

  subject(:sqs_message_consumer) {
    ActiveElasticJob::Rack::SqsMessageConsumer.new(app)
  }

  before do
    allow(sqs_message_consumer).to receive(:secret_key_base) { secret_key_base }
    allow(sqs_message_consumer).to receive(:periodic_tasks_route) { '/periodic_tasks' }
    allow(sqs_message_consumer).to receive(:enabled?) { true }
  end

  it "passes an ordinary request through" do
    expect(app).to receive(:call).with(env).and_return(original_response)
    expect(sqs_message_consumer.call(env)).to eq(original_response)
  end

  context "when user agent matches" do
    let(:job) { Helpers::TestJob.new('test') }
    let(:origin_attribute) { 'AEJ' }

    before do
      verifier = ActiveElasticJob::MessageVerifier.new(secret_key_base)
      message_body = JSON.dump(job.serialize)
      digest = verifier.generate_digest(message_body)
      env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = digest
      env['HTTP_X_AWS_SQSD_ATTR_ORIGIN'] = origin_attribute
      env['HTTP_USER_AGENT'] = 'aws-sqsd/1.1'
      env['rack.input'] = StringIO.new(message_body)
    end

    context "when request was not local" do
      before do
        env['REMOTE_ADDR'] = '64.15.113.183'
      end

      it "responds with a 403 status code" do
        response = sqs_message_consumer.call(env)
        expect(response[0]).to eq('403')
      end
    end

    context "when request was local" do
      before do
        env['REMOTE_ADDR'] = '127.0.0.1'
      end
      context "when origin is not set" do
        let(:origin_attribute) { nil }

        context "when disgest is ommited" do
          before do
            env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = nil
          end
          it "passes request through" do
            expect(app).to receive(:call).with(env).
              and_return(original_response)
            expect(sqs_message_consumer.call(env)).to eq(original_response)
          end
        end

        context "when digest is present" do
          it "intercepts request" do
            expect(app).not_to receive(:call).with(env)
            sqs_message_consumer.call(env)
          end
        end
      end

      context "when origin is not Active Elastic Job" do
        let(:origin_attribute) { "some thing else" }
        before do
          env['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST'] = nil
        end

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
      end
    end

    context "when request was from sqsd to a Docker container" do
      let(:origin_attribute) { "AEJ" }

      before do
        expect(sqs_message_consumer).to receive(:app_runs_in_docker_container?) { true }
      end

      context 'in a single container environment' do
        before do
          env['REMOTE_ADDR'] = '172.17.0.1'
        end

        it "intercepts request and performs the job" do
          expect(app).not_to receive(:call).with(env)

          expect(sqs_message_consumer.call(env)[0]).to eq('200')
        end
      end

      context 'in a multi-container environment' do
        before do
          env['REMOTE_ADDR'] = '172.17.0.2'
        end

        it "intercepts request and performs the job" do
          expect(app).not_to receive(:call).with(env)

          expect(sqs_message_consumer.call(env)[0]).to eq('200')
        end
      end

      context 'with a non-Docker REMOTE_ADDR' do
        before do
          env['REMOTE_ADDR'] = '123.45.0.6'
        end

        it "responds with a 403 status code" do
          expect(app).not_to receive(:call).with(env)

          expect(sqs_message_consumer.call(env)[0]).to eq('403')
        end
      end
    end
  end
end
