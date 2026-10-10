require "rails_helper"

RSpec.describe Incident, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:monitor).class_name("UptimeMonitor") }
    it { is_expected.to belong_to(:alert).optional }
  end

  describe "#duration" do
    it "returns nil when the incident is unresolved" do
      incident = build(:incident, resolved_at: nil)
      expect(incident.duration).to be_nil
    end

    it "returns the elapsed time when resolved" do
      incident = build(:incident, started_at: 1.minute.ago, resolved_at: Time.current)
      expect(incident.duration).to be_within(1.second).of(1.minute)
    end
  end

  describe "#significant?" do
    it "is significant when an alert was sent" do
      incident = build(:incident, started_at: 1.second.ago, resolved_at: Time.current)
      incident.alert_id = 1
      expect(incident).to be_significant
    end

    it "is significant while still unresolved" do
      incident = build(:incident, resolved_at: nil)
      expect(incident).to be_significant
    end

    it "is significant when the outage reached the minimum duration" do
      incident = build(:incident, started_at: 2.minutes.ago, resolved_at: Time.current)
      expect(incident).to be_significant
    end

    it "is not significant for a short, un-alerted blip" do
      incident = build(:incident, started_at: 1.second.ago, resolved_at: Time.current)
      expect(incident).not_to be_significant
    end
  end

  describe ".last_significant_resolved_at" do
    it "ignores insignificant blips when finding the latest resolved incident" do
      create(:incident, started_at: 1.hour.ago, resolved_at: 30.minutes.ago)
      newer = create(:incident, started_at: 2.minutes.ago, resolved_at: 1.minute.ago)
      create(:incident, started_at: 1.second.ago, resolved_at: Time.current)

      expect(described_class.last_significant_resolved_at).to be_within(1.second).of(newer.resolved_at)
    end

    it "returns nil when there are no resolved incidents" do
      create(:incident, resolved_at: nil)
      expect(described_class.last_significant_resolved_at).to be_nil
    end
  end
end
