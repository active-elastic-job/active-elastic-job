module ActiveJob
  module QueueAdapters
    class ActiveElasticJobAdapter
      class << self
        attr_writer :aws_sqs_client

        def enqueue(job)
          queue_url = aws_sqs_client.create_queue(queue_name: job.queue_name.to_s).queue_url
          message_body = JSON.dump(job.serialize)
          aws_sqs_client.send_message(
            queue_url: queue_url,
            message_body: message_body,
            message_attributes: {
              "message_digest" => {
                string_value: message_digest(message_body),
                data_type: "String"
              }
            }
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

        def message_digest(messsage_body)
          secret_key_base = Rails.application.secrets[:secret_key_base]
          verifier = ActiveElasticJob::MessageVerifier.new(secret_key_base)
          verifier.generate_digest(messsage_body)
        end
      end
    end
  end
end
