module ActiveJob
  module QueueAdapters
    class RailsEbJobAdapter
      class << self
        attr_writer :aws_sqs_client

        def enqueue(job)
          queue_url = aws_sqs_client.get_queue_url(queue_name: job.queue_name.to_s).queue_url
          aws_sqs_client.send_message(
            queue_url: queue_url,
            message_body: JSON.dump(job.serialize)
          )
        end

        private

        def aws_sqs_client
          @aws_sqs_client ||= Aws::SQS::Client.new(
            access_key_id: ENV['AWS_ACCESS_KEY_ID'],
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
            region: ENV['AWS_REGION']
          )
        end
      end
    end
  end
end
