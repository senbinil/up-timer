require "rails_helper"

RSpec.describe Alert, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:monitor).class_name("UptimeMonitor").optional }
    it { is_expected.to belong_to(:account).optional }
    it { is_expected.to belong_to(:resolved_by).class_name("Account").optional }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:severity).in_array(%w[critical warning info]) }
    it { is_expected.to validate_presence_of(:message) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns unresolved alerts" do
        active_alert = create(:alert, resolved: false)
        _resolved_alert = create(:alert, resolved: true)

        expect(Alert.active).to contain_exactly(active_alert)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        old = create(:alert, created_at: 1.day.ago)
        new = create(:alert, created_at: Time.current)
        expect(Alert.recent).to eq([ new, old ])
      end
    end

    describe ".by_severity" do
      it "filters by severity" do
        critical = create(:alert, severity: "critical")
        _info = create(:alert, severity: "info")

        expect(Alert.by_severity("critical")).to contain_exactly(critical)
      end

      it "returns all when severity is blank" do
        create(:alert, severity: "critical")
        create(:alert, severity: "info")

        expect(Alert.by_severity(nil).count).to eq(2)
      end
    end
  end

  describe ".heatmap" do
    it "returns an array of daily data points" do
      create(:alert, severity: "critical", created_at: Time.current)
      create(:alert, severity: "warning", created_at: Time.current)

      result = Alert.heatmap(1)

      expect(result.length).to eq(2) # today and yesterday
      expect(result.first).to have_key(:date)
      expect(result.first).to have_key(:count)
      expect(result.first).to have_key(:critical)
      expect(result.first).to have_key(:warning)
      expect(result.first).to have_key(:info)
    end
  end

  describe "callbacks" do
    describe "after_create_commit :notify_recipients" do
      it "enqueues AlertNotificationJob on create" do
        allow(AlertNotificationJob).to receive(:perform_later)
        alert = create(:alert)

        expect(AlertNotificationJob).to have_received(:perform_later).with(alert.id)
      end
    end

    describe "before_destroy :log_destroy" do
      it "creates an action log on destroy" do
        alert = create(:alert)

        expect {
          alert.destroy
        }.to change(ActionLog, :count).by(1)

        log = ActionLog.last
        expect(log.action).to eq("destroyed")
        expect(log.record_type).to eq("Alert")
        expect(log.record_id).to eq(alert.id)
      end
    end
  end
end
