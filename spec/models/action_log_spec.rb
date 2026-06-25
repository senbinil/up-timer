require "rails_helper"

RSpec.describe ActionLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:record_type) }
    it { is_expected.to validate_presence_of(:record_id) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by created_at descending" do
        old = create(:action_log, created_at: 1.day.ago)
        new = create(:action_log, created_at: Time.current)
        expect(ActionLog.recent).to eq([ new, old ])
      end
    end

    describe ".for_record" do
      it "filters by record_type and record_id" do
        matching = create(:action_log, record_type: "UptimeMonitor", record_id: 1)
        _other = create(:action_log, record_type: "Alert", record_id: 1)

        results = ActionLog.for_record("UptimeMonitor", 1)
        expect(results).to contain_exactly(matching)
      end
    end
  end

  describe ".log" do
    it "creates an action log entry" do
      account = create(:account)
      monitor = create(:uptime_monitor)

      log = ActionLog.log(
        action: "created",
        record: monitor,
        account: account,
        metadata: { extra: "info" }
      )

      expect(log).to be_persisted
      expect(log.action).to eq("created")
      expect(log.record_type).to eq("UptimeMonitor")
      expect(log.record_id).to eq(monitor.id)
      expect(log.account).to eq(account)
      expect(log.metadata.symbolize_keys).to include(extra: "info")
    end

    it "allows account to be nil" do
      monitor = create(:uptime_monitor)

      log = ActionLog.log(action: "updated", record: monitor)

      expect(log).to be_persisted
      expect(log.account).to be_nil
    end
  end
end
