module ActiveJob
  module QueueAdapters
    class RailsEbJobAdapter
      class << self
        attr_writer :aws_client
      end
    end
  end
end
