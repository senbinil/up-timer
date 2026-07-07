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

      it "sets delivery method to :mailgun" do
        described_class.configure!
        expect(ActionMailer::Base.delivery_method).to eq(:mailgun)
      end

      it "configures Mailgun client" do
        expect(Mailgun).to receive(:configure)
        described_class.configure!
      end

      it "returns true" do
        expect(described_class.configure!).to be true
      end

      context "with custom API host" do
        before { ENV["MAILGUN_API_HOST"] = "api.eu.mailgun.net" }

        it "configures Mailgun with custom host" do
          expect(Mailgun).to receive(:configure) do |&block|
            config = double
            expect(config).to receive(:api_key=).with("key-test-123")
            expect(config).to receive(:api_host=).with("api.eu.mailgun.net")
            block.call(config)
          end
          described_class.configure!
        end
      end

      context "without API host" do
        it "does not set api_host" do
          expect(Mailgun).to receive(:configure) do |&block|
            config = double
            expect(config).to receive(:api_key=).with("key-test-123")
            expect(config).not_to receive(:api_host=)
            block.call(config)
          end
          described_class.configure!
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
