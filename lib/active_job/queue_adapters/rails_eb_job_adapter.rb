module ActiveJob
  module QueueAdapters
    class RailsEbJobAdapter
      class << self
        attr_writer :aws_client

        def enqueue(job)
          queue_url = @aws_client.get_queue_url(queue_name: job.queue_name.to_s)
          @aws_client.send_message(
            queue_url: queue_url,
            message_body: job.serialize
          )
        end
      end
    end
  end
end
