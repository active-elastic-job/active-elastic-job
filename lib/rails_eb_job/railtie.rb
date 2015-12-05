module RailsEbJob
  class Railtie < Rails::Railtie
    initializer "rails_eb_job.insert_middleware" do |app|
      app.config.middleware.use "RailsEbJob::Rack::SqsProcessor"
    end
  end
end
