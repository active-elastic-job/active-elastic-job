require 'aws-sdk-core'
require 'active_elastic_job/version'
require 'active_job/queue_adapters/active_elastic_job_adapter'
require 'active_elastic_job/rack/sqs_processor'

module ActiveElasticJob; end;

require "active_elastic_job/railtie" if defined? Rails
