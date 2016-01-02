require "action_dispatch"

module ActiveElasticJob
  module Rack
    class SqsMessageConsumer
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new env
        if request.headers['User-Agent'] =~ /aws-sqsd/
          begin
            verify(request)
            job = JSON.load(request.body)
            ActiveJob::Base.execute(job)
          rescue ActiveElasticJob::MessageVerifier::InvalidDigest => e
            return ['403', {'Content-Type' => env['text/plain'] }, ["incorrect digest"]]
          rescue StandardError => e
            return ['500', {'Content-Type' => env['text/plain'] }, [e.message]]
          end
          return ['200', {'Content-Type' => 'application/json' }, [ '' ]]
        end
        @app.call(env)
      end

      private

      def verify(request)
        secret_key_base = Rails.application.secrets[:secret_key_base]
        verifier = ActiveElasticJob::MessageVerifier.new(secret_key_base)
        digest = request.headers['HTTP_X_AWS_SQSD_ATTR_MESSAGE_DIGEST']
        verifier.verify(request.body.string, digest)
      end
    end
  end
end
