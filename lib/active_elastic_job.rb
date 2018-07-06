require 'aws-sdk'
require 'active_elastic_job/version'
require 'active_elastic_job/md5_message_digest_calculation'
require 'active_job/queue_adapters/active_elastic_job_adapter'
require 'active_elastic_job/rack/sqs_message_consumer'
require 'active_elastic_job/message_verifier'

module ActiveElasticJob
  ACRONYM = 'AEJ'.freeze
end

require "active_elastic_job/railtie" if defined? Rails
