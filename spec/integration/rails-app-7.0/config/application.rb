require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Not worth the headache for testing
    config.action_controller.default_protect_from_forgery = false

    config.active_job.queue_adapter = :active_elastic_job

    config.force_ssl = true
    config.ssl_options = { redirect: { exclude: -> request { request.path =~ /health/ } } }
  end
end
