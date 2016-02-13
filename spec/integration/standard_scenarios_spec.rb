require 'spec_helper'
require 'timeout'

describe "standard scenarios", slow: true, deployed: true do
  let(:random_string) { SecureRandom.hex }

  before(:all) do
    @rails_app = Helpers::RailsApp.new
    @rails_app.deploy
  end

  it "posts a job to the queue and processes it" do
    expect(@rails_app.fetch_random_strings).to_not include(random_string)
    @rails_app.create_random_string(random_string)
    expect(@rails_app.fetch_random_strings).to include(random_string)
    @rails_app.create_delete_job(random_string)
    expect(@rails_app).to have_deleted(random_string)
  end

  context "when job is scheduled for future processing" do
    let(:delay) { 5 }

    it "waits until scheduled point in time" do
      expect(@rails_app.fetch_random_strings).to_not include(random_string)
      @rails_app.create_random_string(random_string)
      expect(@rails_app.fetch_random_strings).to include(random_string)
      @rails_app.create_delete_job(random_string, delay)

      scheduled_at = Time.now + delay.seconds
      while ((Time.now + 1) < scheduled_at) do
        expect(@rails_app.fetch_random_strings).to include(random_string)
        sleep 1
      end
      expect(@rails_app).to have_deleted(random_string)
    end
  end
end
