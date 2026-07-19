require "rails_helper"

RSpec.describe MailAdapter::Mailgun do
  before do
    ActionMailer::Base.delivery_method = :test
  end

  describe ".configure!" do
    context "with all env vars" do
      before do
        ENV["MAILGUN_API_KEY"] = "key-test-123"
        ENV["MAILGUN_DOMAIN"] = "mg.example.com"
      end

      after do
        ENV.delete("MAILGUN_API_KEY")
        ENV.delete("MAILGUN_DOMAIN")
        ENV.delete("MAILGUN_API_HOST")
      end

      it "sets mailgun_settings on ActionMailer::Base" do
        described_class.configure!
        expect(ActionMailer::Base.mailgun_settings).to eq({
          api_key: "key-test-123",
          domain: "mg.example.com",
          api_host: "api.mailgun.net"
        })
      end

      it "sets delivery method to :mailgun" do
        described_class.configure!
        expect(ActionMailer::Base.delivery_method).to eq(:mailgun)
      end

      it "returns true" do
        expect(described_class.configure!).to be true
      end

      context "with custom API host" do
        before { ENV["MAILGUN_API_HOST"] = "api.eu.mailgun.net" }

        it "sets api_host to the custom value" do
          described_class.configure!
          expect(ActionMailer::Base.mailgun_settings[:api_host]).to eq("api.eu.mailgun.net")
        end
      end

      context "without API host" do
        it "defaults api_host to api.mailgun.net" do
          described_class.configure!
          expect(ActionMailer::Base.mailgun_settings[:api_host]).to eq("api.mailgun.net")
        end
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
