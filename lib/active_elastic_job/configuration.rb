require "ostruct"

module ActiveElasticJob
  def self.configure(&block)
    Configuration.configure &block
  end

  def self.configuration
    Configuration.configuration
  end

  # This class provides the pattern to set and retreive configuration settings
  # for the gem. A configuration attribute can be set by calling a setter
  # method directly from +ActiveElasticJob::Configuration.configuration+, or
  # by calling a block on +ActiveElasticJob::Configuration.configure+.
  #
  # For simplicity, two proxy methods exist to access and set configuration
  # attributes. This is also true for calling a block to set attributes. The
  # methods are:
  #
  # * ActiveElasticJob.configuration (a proxy to +ActiveElasticJob::Configuration.configuration+)
  # * ActiveElasticJob.configure (a proxy to +ActiveElasticJob::Configuration.configure+)
  #
  # Examples:
  #
  #   # Setting an allowed network.
  #   ActiveElasticJob.configure do |config|
  #     config.allowed_network = "172.17.0.0/16"
  #   end
  #
  #   # Retrieving an allowed network setting.
  #   ActiveElasticJob.configuration.allowed_network
  #   => "172.17.0.0/16"
  class Configuration
    def self.configuration
      @configuration ||= OpenStruct.new
    end

    def self.configuration=(configuration)
      @configuraiton = configuration
    end

    def self.configure
      yield configuration
    end
  end
end
