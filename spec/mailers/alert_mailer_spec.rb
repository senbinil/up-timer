require "rails_helper"

RSpec.describe AlertMailer, type: :mailer do
  let(:alert) { create(:alert, severity: "critical") }

  describe "sender address" do
    before { @original_mail_from = ENV.delete("MAIL_FROM") }
    after do
      @original_mail_from ? ENV["MAIL_FROM"] = @original_mail_from : ENV.delete("MAIL_FROM")
    end

    it "sends from MAIL_FROM when it is configured" do
      ENV["MAIL_FROM"] = "alerts@uptimer.test"

      mail = AlertMailer.alert_down("ops@example.com", alert)

      expect(mail.from).to eq([ "alerts@uptimer.test" ])
    end

    it "raises instead of silently using a placeholder when MAIL_FROM is missing" do
      expect {
        AlertMailer.alert_down("ops@example.com", alert).from
      }.to raise_error(KeyError, /MAIL_FROM/)
    end
  end
end
