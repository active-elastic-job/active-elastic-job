require 'aws-sdk-core'
require 'rails_eb_job/version'
require 'active_job/queue_adapters/rails_eb_job_adapter'
require 'rails_eb_job/rack/sqs_processor'

module RailsEbJob; end;

require "rails_eb_job/railtie" if defined? Rails
