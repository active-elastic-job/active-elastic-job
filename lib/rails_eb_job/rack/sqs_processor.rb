require "action_dispatch"

module RailsEbJob
  module Rack
    class SqsProcessor
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new env
        if request.headers['User-Agent'] =~ /aws-sqsd/
          begin
            job = JSON.load(request.body)
            ActiveJob::Base.execute(job)
          rescue StandardError => e
            return ['500', {'Content-Type' => env['text/plain'] }, [e.message]]
          end
          return ['200', {'Content-Type' => 'application/json' }, [ '' ]]
        end
        @app.call(env)
      end
    end
  end
end
