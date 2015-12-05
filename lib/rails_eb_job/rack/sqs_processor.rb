module RailsEbJob
  module Rack
    class SqsProcessor
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end
