require "rails_helper"

RSpec.describe MailAdapter::Mailgun do
  before do
    ActionMailer::Base.delivery_method = :test
  end

  describe ".configure!" do
    context "with valid env vars" do
      before do
        ENV["MAILGUN_API_KEY"] = "key-test-123"
        ENV["MAILGUN_DOMAIN"] = "mg.example.com"
      end

      after do
        ENV.delete("MAILGUN_API_KEY")
        ENV.delete("MAILGUN_DOMAIN")
      end

      it "sets delivery method to :mailgun" do
        described_class.configure!
        expect(Rails.application.config.action_mailer.delivery_method).to eq(:mailgun)
      end

      it "configures Mailgun client" do
        expect(Mailgun).to receive(:configure)
        described_class.configure!
      end

      it "returns true" do
        expect(described_class.configure!).to be true
      end
    end

    context "with missing API key" do
      before do
        ENV["MAILGUN_API_KEY"] = ""
        ENV["MAILGUN_DOMAIN"] = "mg.example.com"
      end

      after do
        ENV.delete("MAILGUN_API_KEY")
        ENV.delete("MAILGUN_DOMAIN")
      end

      it "returns false" do
        expect(described_class.configure!).to be false
      end
    end

    context "with missing domain" do
      before do
        ENV["MAILGUN_API_KEY"] = "key-test-123"
        ENV["MAILGUN_DOMAIN"] = ""
      end

      after do
        ENV.delete("MAILGUN_API_KEY")
        ENV.delete("MAILGUN_DOMAIN")
      end

      it "returns false" do
        expect(described_class.configure!).to be false
      end
    end
  end
end
