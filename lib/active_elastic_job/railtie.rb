module ActiveElasticJob
  class Railtie < Rails::Railtie
    config.active_elastic_job = ActiveSupport::OrderedOptions.new
    config.active_elastic_job.aws_region = ENV['AWS_REGION']
    config.active_elastic_job.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
    config.active_elastic_job.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || ENV['AWS_SECRET_KEY'] || ENV['AMAZON_SECRET_ACCESS_KEY']
    config.active_elastic_job.disable_sqs_confumer = ENV['DISABLE_SQS_CONSUMER']

    initializer "active_elastic_job.insert_middleware" do |app|
      disabled = app.config.active_elastic_job.disable_sqs_confumer
      if disabled == 'false' || disabled.nil?
        if app.config.force_ssl
          app.config.middleware.insert_before(ActionDispatch::SSL,ActiveElasticJob::Rack::SqsMessageConsumer)
        else
          app.config.middleware.use(ActiveElasticJob::Rack::SqsMessageConsumer)
        end
      end
    end
  end
end
