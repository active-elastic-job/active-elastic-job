module ActiveElasticJob
  class Railtie < Rails::Railtie
    initializer "active_elastic_job.insert_middleware" do |app|
      disabled = ENV['DISABLE_SQS_CONSUMER']
      if disabled == 'false' || disabled.nil?
        if app.config.force_ssl
          app.config.middleware.insert_before("ActionDispatch::SSL","ActiveElasticJob::Rack::SqsMessageConsumer")
        else
          app.config.middleware.use("ActiveElasticJob::Rack::SqsMessageConsumer")
        end
      end
    end
  end
end
