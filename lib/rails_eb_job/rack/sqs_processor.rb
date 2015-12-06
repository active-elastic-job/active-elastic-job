require "action_dispatch"

module RailsEbJob
  module Rack
    class SqsProcessor
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new env
        @app.call(env)
      end
    end
  end
end
