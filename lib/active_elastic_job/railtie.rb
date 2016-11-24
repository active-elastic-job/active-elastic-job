module ActiveElasticJob
  class Railtie < Rails::Railtie
    config.active_elastic_job = ActiveSupport::OrderedOptions.new
    config.active_elastic_job.process_jobs = ENV['PROCESS_ACTIVE_ELASTIC_JOBS'] == 'true' || false
    config.active_elastic_job.aws_credentials = Aws::InstanceProfileCredentials.new

    initializer "active_elastic_job.insert_middleware" do |app|
      if app.config.active_elastic_job.process_jobs == true
        if app.config.force_ssl
          app.config.middleware.insert_before(ActionDispatch::SSL,ActiveElasticJob::Rack::SqsMessageConsumer)
        else
          app.config.middleware.use(ActiveElasticJob::Rack::SqsMessageConsumer)
        end
      end
    end
  end
end
