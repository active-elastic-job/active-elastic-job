require 'aws-sdk-sqs'
require 'active_elastic_job/version'
require 'active_elastic_job/md5_message_digest_calculation'
require 'active_job/queue_adapters/active_elastic_job_adapter'
require 'active_elastic_job/rack/sqs_message_consumer'
require 'active_elastic_job/message_verifier'

module ActiveElasticJob
  ACRONYM = 'AEJ'.freeze

  class << self
    attr_accessor :fifo_content_deduplication_queues

    def use_content_deduplication_id?(queue_name)
      return false unless fifo_content_deduplication_queues.is_a?(Array)

      fifo_content_deduplication_queues.include?(queue_name)
    end
  end
end

require "active_elastic_job/railtie" if defined? Rails
