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

        it "passes api_host to delivery method settings" do
          expect(ActionMailer::Base).to receive(:add_delivery_method)
            .with(:mailgun, described_class::MailgunDelivery,
                  api_key: "key-test-123", domain: "mg.example.com",
                  api_host: "api.eu.mailgun.net")
          described_class.configure!
        end
      end

      context "without API host" do
        it "does not set api_host on delivery method settings" do
          expect(ActionMailer::Base).to receive(:add_delivery_method)
            .with(:mailgun, described_class::MailgunDelivery,
                  api_key: "key-test-123", domain: "mg.example.com",
                  api_host: nil)
          described_class.configure!
        end

        it "does not configure Mailgun client with api_host" do
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

  describe MailAdapter::Mailgun::MailgunDelivery do
    let(:settings) do
      { api_key: "key-test-123", domain: "mg.example.com", api_host: nil }
    end
    let(:delivery) { described_class.new(settings) }

    let(:mail) do
      mail = double("Mail::Message", subject: "Test subject",
        html_part: double(body: double(to_s: "<p>HTML</p>")),
        text_part: double(body: double(to_s: "Text body")))
      allow(mail).to receive(:[]).with(:from).and_return(double(to_s: "Sender <sender@example.com>"))
      allow(mail).to receive(:[]).with(:to).and_return(double(to_s: "recipient@example.com"))
      mail
    end

    describe "#deliver!" do
      it "creates a Mailgun::Client with api_key and default host" do
        client = instance_double("Mailgun::Client", send_message: true)
        expect(::Mailgun::Client).to receive(:new)
          .with("key-test-123", "api.mailgun.net")
          .and_return(client)
        expect(client).to receive(:send_message).with("mg.example.com", anything)
        delivery.deliver!(mail)
      end

      context "with custom api_host" do
        let(:settings) do
          { api_key: "key-test-123", domain: "mg.example.com", api_host: "api.eu.mailgun.net" }
        end

        it "creates a Mailgun::Client with the custom host" do
          client = instance_double("Mailgun::Client", send_message: true)
          expect(::Mailgun::Client).to receive(:new)
            .with("key-test-123", "api.eu.mailgun.net")
            .and_return(client)
          expect(client).to receive(:send_message).with("mg.example.com", anything)
          delivery.deliver!(mail)
        end
      end

      it "builds the message hash from the mail object" do
        client = instance_double("Mailgun::Client")
        allow(::Mailgun::Client).to receive(:new).and_return(client)

        expected_message = {
          from: "Sender <sender@example.com>",
          to: "recipient@example.com",
          subject: "Test subject",
          html: "<p>HTML</p>",
          text: "Text body"
        }

        expect(client).to receive(:send_message).with("mg.example.com", expected_message)
        delivery.deliver!(mail)
      end

      it "omits nil parts from the message" do
        html_mail = double("Mail::Message", subject: "No HTML",
          html_part: nil,
          text_part: double(body: double(to_s: "Just text")))
        allow(html_mail).to receive(:[]).with(:from).and_return(double(to_s: "<sender@example.com>"))
        allow(html_mail).to receive(:[]).with(:to).and_return(double(to_s: "to@example.com"))

        client = instance_double("Mailgun::Client")
        allow(::Mailgun::Client).to receive(:new).and_return(client)

        expect(client).to receive(:send_message) do |_domain, message|
          expect(message.keys).not_to include(:html)
          expect(message[:text]).to eq("Just text")
        end
        delivery.deliver!(html_mail)
      end
    end
  end
end
