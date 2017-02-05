require 'spec_helper'
require 'timeout'

RAILS_START_UP_UPPER_BOUNDARY = 10 # in seconds
describe "performance" do
  before(:all) do
    @rails_app = Helpers::RailsApp.new("#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}")
  end

  describe "rails start up time" do
    it "performs under #{RAILS_START_UP_UPPER_BOUNDARY} seconds" do
      begin
        Timeout::timeout(RAILS_START_UP_UPPER_BOUNDARY) do
          @rails_app.run_in_rails_app_root_dir do
            system("bundle exec rails runner \"puts 'hello world!'\" ")
          end
        end
      rescue Timeout::Error
        fail "Rails app has not started within #{RAILS_START_UP_UPPER_BOUNDARY} seconds"
      end
    end
  end
end
