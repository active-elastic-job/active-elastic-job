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
    # Amazon SQS queue specified by the job's queue name,
    # see <tt>ActiveJob::Base.queue_as</tt>
    #
    # To use Active Elastic Job, set the queue_adapter config
    # to +:active_elastic_job+.
    #
    #   Rails.application.config.active_job.queue_adapter = :active_elastic_job
    class ActiveElasticJobAdapter
      MAX_MESSAGE_SIZE = (256 * 1024)
      MAX_DELAY_IN_MINUTES = 15

      extend ActiveElasticJob::MD5MessageDigestCalculation

      class Error < RuntimeError; end;

      # Raised when job exceeds 256 KB in its serialized form. The limit is
      # imposed by Amazon SQS.
      class SerializedJobTooBig < Error
        def initialize(serialized_job)
          super(<<-MSG)
            The job contains #{serialized_job.bytesize} bytes in its serialized form,
            which exceeds the allowed maximum of #{MAX_MESSAGE_SIZE} bytes imposed by Amazon SQS.
          MSG
        end
      end

      # Raised when job queue does not exist. The job queue is determined by
      # <tt>ActiveJob::Base.queue_as</tt>. You can either: (1) create a new
      # Amazon SQS queue and attach a worker environment to it, or (2) select a
      # different queue for your jobs.
      #
      # Example:
      # * Open your AWS console and create an SQS queue named +high_priority+ in
      #   the same AWS region of your Elastic Beanstalk environments.
      # * Queue your jobs accordingly:
      #
      #  class MyJob < ActiveJob::Base
      #    queue_as :high_priority
      #    #..
      #  end
      class NonExistentQueue < Error
        def initialize(queue_name, aws_region)

          super(<<-MSG)
            The job is bound to queue at #{queue_name}.
            Unfortunately a queue with this name does not exist in this
            region. Either create an Amazon SQS queue named #{queue_name} -
            you can do this in AWS console, make sure to select region
            '#{aws_region}' - or you
            select another queue for your jobs.
          MSG
        end
      end

      # Raised when calculated MD5 digest does not match the MD5 Digest
      # of the response from Amazon SQS.
      class MD5MismatchError < Error
        def initialize(message_id, calculated, returned)

          super(<<-MSG)
            MD5 '#{returned}' returned by Amazon SQS does not match the
            calculation on the original request which was '#{calculated}'.
            The message with Message ID #{message_id} sent to SQS might be
            corrupted.
          MSG
        end
      end

      # Raised when the delay is longer than the MAX_DELAY_IN_MINUTES
      class DelayTooLong < RangeError
        def initialize()
          super(<<-MSG)
            Jobs cannot be scheduled more than #{MAX_DELAY_IN_MINUTES} minutes
            into the future.
            See http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html
            for further details!
          MSG
        end
      end

      def enqueue(job) #:nodoc:
        self.class.enqueue job
      end

      def enqueue_at(job, timestamp) #:nodoc:
        self.class.enqueue_at(job, timestamp)
      end

      class << self
        def enqueue(job) #:nodoc:
          enqueue_at(job, Time.now)
        end

        def enqueue_at(job, timestamp) #:nodoc:
          serialized_job = JSON.dump(job.serialize)
          check_job_size!(serialized_job)
          message = build_message(job.queue_name, serialized_job, timestamp)
          resp = aws_sqs_client.send_message(message)
          unless aws_client_verifies_md5_digests?
            verify_md5_digests!(
              resp,
              message[:message_body],
              message[:message_attributes])
          end
          job.provider_job_id = resp.message_id
        rescue Aws::SQS::Errors::NonExistentQueue => e
          unless @queue_urls[job.queue_name.to_s].nil?
            @queue_urls[job.queue_name.to_s] = nil
            retry
          end
          raise NonExistentQueue.new(job, aws_region)
        rescue Aws::Errors::ServiceError => e
          raise Error, "Could not enqueue job, #{e.message}"
        end

        private

        def aws_client_verifies_md5_digests?
          Gem::Version.new(Aws::CORE_GEM_VERSION) >= Gem::Version.new('2.2.19'.freeze)
        end

        def build_message(queue_name, serialized_job, timestamp)
          args = {
            queue_url: queue_url(queue_name),
            message_body: serialized_job,
            delay_seconds: calculate_delay(timestamp),
            message_attributes: build_message_attributes(serialized_job)
          }

          if queue_name.split('.').last == 'fifo'
            args.merge!(fifo_required_params(serialized_job))
          end

          return args
        end

        def build_message_attributes(serialized_job)
          {
            "message-digest".freeze => {
              string_value: message_digest(serialized_job),
              data_type: "String".freeze
            },
            origin: {
              string_value: ActiveElasticJob::ACRONYM,
              data_type: "String".freeze
            }
          }
        end

        def fifo_required_params(serialized_job)
          parsed_job = JSON.parse(serialized_job)

          {
            message_group_id: parsed_job['job_class'],
            message_deduplication_id: parsed_job['job_id']
          }
        end

        def queue_url(queue_name)
          cache_key = queue_name.to_s
          @queue_urls ||= { }
          return @queue_urls[cache_key] if @queue_urls[cache_key]
          resp = aws_sqs_client.get_queue_url(queue_name: queue_name.to_s)
          @queue_urls[cache_key] = resp.queue_url
        rescue Aws::SQS::Errors::NonExistentQueue => e
          raise NonExistentQueue.new(queue_name, aws_region)
        end

        def calculate_delay(timestamp)
          delay = (timestamp - Time.current.to_f).to_i + 1
          if delay > MAX_DELAY_IN_MINUTES.minutes
            raise DelayTooLong.new
          end
          delay = 0 if delay < 0
          delay
        end

        def check_job_size!(serialized_job)
          if serialized_job.bytesize > MAX_MESSAGE_SIZE
            raise SerializedJobTooBig, serialized_job
          end
        end

        def aws_sqs_client
          options = {
            credentials: aws_sqs_client_credentials,
            region: aws_region
          }
          endpoint = Rails.application.config.active_elastic_job.endpoint
          options[:endpoint] = endpoint if endpoint.present?
          @aws_sqs_client ||= Aws::SQS::Client.new(options)
        end

        def aws_sqs_client_credentials
          @aws_credentials ||= if config.aws_credentials.kind_of?(Proc)
                                 config.aws_credentials.call
                               else
                                 config.aws_credentials
                               end
        end

        def aws_region
          config.aws_region
        end

        def config
          Rails.application.config.active_elastic_job
        end

        def message_digest(message_body)
          @verifier ||= ActiveElasticJob::MessageVerifier.new(secret_key_base)
          @verifier.generate_digest(message_body)
        end

        def verify_md5_digests!(response, message_body, message_attributes)
          calculated = md5_of_message_body(message_body)
          returned = response.md5_of_message_body
          if calculated != returned
            raise MD5MismatchError.new response.message_id, calculated, returned
          end

          if message_attributes
            calculated = md5_of_message_attributes(message_attributes)
            returned = response.md5_of_message_attributes
            if calculated != returned
              raise MD5MismatchError.new response.message_id, calculated, returned
            end
          end
        end

        def secret_key_base
          config.secret_key_base
        end
      end
    end
  end
end
