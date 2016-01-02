require "action_dispatch"

module ActiveElasticJob
  module Rack
    # This middleware intercepts requests which are sent by the SQS daemon
    # running in {Amazon Elastic Beanstalk worker environments}[http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html].
    # It does this by looking at the +User-Agent+ header.
    # Furthermore, it verifies the digest which is sent along with a legit SQS message,
    # and passed as an HTTP header in the resulting request.
    # The digest is based on Rails' +secrets.secret_key_base+.
    # Therefore, the application running in the web environment, which generates
    # the digest, and the application running in the worker
    # environment, which verifies the digest, have to use the *same*
    # +secrets.secret_key_base+ setting.
    class SqsMessageConsumer
      def initialize(app) #:nodoc:
        @app = app
      end

      def call(env) #:nodoc:
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
