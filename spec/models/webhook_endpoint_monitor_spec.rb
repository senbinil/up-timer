require "rails_helper"

RSpec.describe WebhookEndpointMonitor, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:webhook_endpoint) }
    it { is_expected.to belong_to(:monitor).class_name("UptimeMonitor") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:events) }
  end

  describe "#event_list" do
    it "splits comma-separated events into an array" do
      pair = build(:webhook_endpoint_monitor, events: "check_result,status_change")
      expect(pair.event_list).to eq(%w[check_result status_change])
    end

    it "handles whitespace around events" do
      pair = build(:webhook_endpoint_monitor, events: " check_result , status_change ")
      expect(pair.event_list).to eq(%w[check_result status_change])
    end

    it "returns empty array for nil" do
      pair = build(:webhook_endpoint_monitor, events: nil)
      expect(pair.event_list).to eq([])
    end
  end

  describe "#sends_event?" do
    it "returns true if event type is in the list" do
      pair = build(:webhook_endpoint_monitor, events: "check_result,status_change")
      expect(pair.sends_event?("check_result")).to be true
      expect(pair.sends_event?("status_change")).to be true
    end

    it "returns false if event type is not in the list" do
      pair = build(:webhook_endpoint_monitor, events: "check_result")
      expect(pair.sends_event?("status_change")).to be false
    end
  end
end
