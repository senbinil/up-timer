require "rails_helper"

RSpec.describe MonitorCheck, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:monitor).class_name("UptimeMonitor") }
  end

  describe "#ssl_days_remaining" do
    it "returns the number of days until SSL expiration" do
      check = build(:monitor_check, ssl_expires_at: 30.days.from_now)
      expect(check.ssl_days_remaining).to be_within(1).of(30)
    end

    it "returns nil when ssl_expires_at is nil" do
      check = build(:monitor_check, ssl_expires_at: nil)
      expect(check.ssl_days_remaining).to be_nil
    end
  end
end
