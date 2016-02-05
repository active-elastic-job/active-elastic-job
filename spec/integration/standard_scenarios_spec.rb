require 'spec_helper'
require 'timeout'

describe "standard scenarios", slow: true, deployed: true do
  let(:random_string) { SecureRandom.hex }

  before(:all) do
    deploy
  end

  it "posts a job to the queue and processes it" do
    expect(fetch_random_strings).to_not include(random_string)
    create_random_string(random_string)
    expect(fetch_random_strings).to include(random_string)
    create_job(random_string)
    expect do
      Timeout::timeout(5) do
        while(fetch_random_strings.include?(random_string)) do
          sleep 1
        end
      end
    end.not_to raise_error
  end

  context "when job is scheduled for future processing" do
    let(:delay) { 15 }

    it "waits until scheduled point in time" do
      expect(fetch_random_strings).to_not include(random_string)
      create_random_string(random_string)
      expect(fetch_random_strings).to include(random_string)
      create_job(random_string, delay)

      scheduled_at = Time.now + delay.seconds
      while ((Time.now + 1) < scheduled_at) do
        expect(fetch_random_strings).to include(random_string)
        sleep 1
      end
      expect do
        Timeout::timeout(5) do
          while(fetch_random_strings.include?(random_string)) do
            sleep 1
          end
        end
      end.not_to raise_error
    end
  end
end
