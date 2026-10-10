require "rails_helper"

RSpec.describe MonitorStatusService do
  let(:monitor) { create(:uptime_monitor, down_threshold: 2) }

  before do
    create(:alert_trigger, name: "Node Offline", severity: "critical", email_notify: true)
    ActionMailer::Base.deliveries.clear
  end

  def record_check(status, at:)
    create(:monitor_check, monitor: monitor, status: status, checked_at: at)
  end

  describe "first failure" do
    it "opens an incident and flips status down without alerting" do
      record_check("down", at: 1.minute.ago)

      expect { described_class.call(monitor) }
        .to change { monitor.incidents.where(resolved_at: nil).count }.from(0).to(1)

      expect(monitor.reload.status).to eq("down")
      expect(monitor.alerts.count).to eq(0)
    end

    it "backfills started_at from the failing check" do
      check = record_check("down", at: 1.minute.ago)

      described_class.call(monitor)

      expect(monitor.incidents.last.started_at).to be_within(1.second).of(check.checked_at)
    end
  end

  describe "sustained failure past the threshold" do
    before do
      record_check("down", at: 3.minutes.ago)
      described_class.call(monitor)
    end

    it "creates a single alert linked to the incident" do
      record_check("down", at: 2.minutes.ago)

      expect { described_class.call(monitor) }.to change { monitor.alerts.count }.from(0).to(1)

      incident = monitor.incidents.where(resolved_at: nil).first
      expect(incident.alert_id).to eq(monitor.alerts.first.id)
    end

    it "does not create a duplicate alert on further failures" do
      record_check("down", at: 2.minutes.ago)
      described_class.call(monitor)
      record_check("down", at: 1.minute.ago)
      described_class.call(monitor)

      expect(monitor.alerts.count).to eq(1)
    end
  end

  describe "recovery" do
    it "resolves the incident, flips up, and emails when the incident alerted" do
      create(:recipient, email: "ops@example.com")
      record_check("down", at: 3.minutes.ago)
      described_class.call(monitor)
      record_check("down", at: 2.minutes.ago)
      described_class.call(monitor)

      record_check("up", at: 1.minute.ago)

      expect { described_class.call(monitor) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(monitor.reload.status).to eq("up")
      expect(monitor.incidents.where(resolved_at: nil).count).to eq(0)
      expect(monitor.alerts.where(resolved: false).count).to eq(0)
    end

    it "records a silent blip without emailing" do
      create(:recipient, email: "ops@example.com")
      record_check("down", at: 2.minutes.ago)
      described_class.call(monitor)
      record_check("up", at: 90.seconds.ago)

      expect { described_class.call(monitor) }.not_to change { ActionMailer::Base.deliveries.count }

      expect(monitor.reload.status).to eq("up")
      incident = monitor.incidents.first
      expect(incident.resolved_at).to be_present
      expect(incident).not_to be_significant
    end

    it "resolves only the outage alert and leaves manually-raised alerts open" do
      record_check("down", at: 3.minutes.ago)
      described_class.call(monitor)
      record_check("down", at: 2.minutes.ago)
      described_class.call(monitor)

      outage_alert = monitor.incidents.first.alert
      manual_alert = create(:alert, monitor: monitor, alert_trigger: create(:alert_trigger, name: "Security Breach"))

      record_check("up", at: 1.minute.ago)
      described_class.call(monitor)

      expect(outage_alert.reload).to be_resolved
      expect(manual_alert.reload).not_to be_resolved
    end
  end
end
