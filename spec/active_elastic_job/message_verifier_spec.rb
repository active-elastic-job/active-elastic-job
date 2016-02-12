require 'spec_helper'

describe ActiveElasticJob::MessageVerifier do
  let(:secret) { 's3krit' }
  let(:message) { "this is a message" }

  subject(:verifier) { ActiveElasticJob::MessageVerifier.new(secret) }

  context "when digest is correct" do
    let(:digest) { verifier.generate_digest(message) }
    it "verfies" do
      expect(verifier.verify(message, digest)).to be_truthy
    end
  end

  context "when digest is incorrect" do
    let(:digest) { 'sth incorrect' }

    it "does not verify" do
      expect { verifier.verify!(message, digest) }.to raise_error(ActiveElasticJob::MessageVerifier::InvalidDigest)
    end
  end
end
