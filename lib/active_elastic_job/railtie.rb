module ActiveElasticJob
  class Railtie < Rails::Railtie
    config.active_elastic_job = ActiveSupport::OrderedOptions.new
    process_active_elastic_jobs = ENV['PROCESS_ACTIVE_ELASTIC_JOBS']
    config.active_elastic_job.process_jobs = !process_active_elastic_jobs.nil? && process_active_elastic_jobs.downcase == 'true'
    config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
    config.active_elastic_job.aws_region = ENV['AWS_REGION']
    config.active_elastic_job.periodic_tasks_route = '/periodic_tasks'.freeze

    initializer "active_elastic_job.insert_middleware" do |app|
      if app.config.active_elastic_job.secret_key_base.blank?
        app.config.active_elastic_job.secret_key_base = app.secrets[:secret_key_base]
      end

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
