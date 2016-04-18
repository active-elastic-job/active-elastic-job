require 'spec_helper'

describe ActiveElasticJob::Configuration do
  context "when using the configuration pattern" do
    it "sets values within a block" do
      ActiveElasticJob.configure do |c|
        c.allowed_network = '172.17.0.0/16'
      end

      expect(ActiveElasticJob.configuration.allowed_network).to eq('172.17.0.0/16')
    end

    it "sets a value calling the setter method directly" do
      ActiveElasticJob.configuration.allowed_network = '172.17.0.0/16'
      expect(ActiveElasticJob.configuration.allowed_network).to eq('172.17.0.0/16')
    end
  end

  context "class methods" do
    context ".configuration" do
      it "returns the configuration object" do
        expect(ActiveElasticJob::Configuration.configuration).to be_a(OpenStruct)
      end

      it "sets the configuration object" do
        new_configuration = OpenStruct.new(allowed_network: '172.17.0.0/16')
        ActiveElasticJob::Configuration.configuration = new_configuration
        expect(ActiveElasticJob::Configuration.configuration).to eq(new_configuration)
      end
    end
  end
end
