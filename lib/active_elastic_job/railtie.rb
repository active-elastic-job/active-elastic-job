module ActiveElasticJob
  class Railtie < Rails::Railtie
    initializer "active_elastic_job.insert_middleware" do |app|
      app.config.middleware.use "ActiveElasticJob::Rack::SqsProcessor"
    end
  end
end
