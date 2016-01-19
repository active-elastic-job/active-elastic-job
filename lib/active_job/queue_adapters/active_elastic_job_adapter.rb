module ActiveJob
  module QueueAdapters
    # == Active Elastic Job adapter for Active Job
    #
    # Active Elastic Job provides (1) an adapter (this class) for Rails'
    # Active Job framework and (2) a Rack middleware to process job requests,
    # which are sent by the SQS daemon running in {Amazon Elastic Beanstalk worker
    # environments}[http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html].
    #
    # This adapter serializes job objects and sends them as a message to an
    # Amazon SQS queue specified by the job's queue name, see <tt>ActiveJob::Base.queue_as</tt>
    #
    # To use Active Elastic Job, set the queue_adapter config to +:active_elastic_job+.
    #
    #   Rails.application.config.active_job.queue_adapter = :active_elastic_job
    class ActiveElasticJobAdapter
      class << self
        def enqueue(job) #:nodoc:
          enqueue_at(job, Time.now)
        end

        def enqueue_at(job, timestamp) #:nodoc:
          queue_url = aws_sqs_client.create_queue(queue_name: job.queue_name.to_s).queue_url
          message_body = JSON.dump(job.serialize)
          aws_sqs_client.send_message(
            queue_url: queue_url,
            message_body: message_body,
            delay_seconds: calculate_delay(timestamp),
            message_attributes: {
              "message_digest" => {
                string_value: message_digest(message_body),
                data_type: "String"
              }
            }
          )
        end

        private

        def calculate_delay(timestamp)
          delay = (timestamp - Time.current.to_f).to_i + 1
          if delay > 15.minutes
            msg =<<-MSG
Jobs cannot be scheduled more than 15 minutes into the future.
See http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html
for further details!
            MSG
            raise RangeError, msg if delay > 15.minutes
          end
          delay
        end

        def aws_sqs_client
          Aws::SQS::Client.new(
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
