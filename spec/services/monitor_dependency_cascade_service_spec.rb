require "rails_helper"

RSpec.describe MonitorDependencyCascadeService do
  describe ".cascade_down" do
    it "marks dependents as down and dependency_affected" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)

      described_class.cascade_down(parent)

      expect(child.reload.status).to eq("down")
      expect(child).to be_dependency_affected
    end

    it "creates incidents for each dependent" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)

      expect {
        described_class.cascade_down(parent)
      }.to change(Incident, :count).by(1)

      expect(child.incidents.last).to be_present
    end

    it "creates action logs for each dependent" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)

      expect {
        described_class.cascade_down(parent)
      }.to change(ActionLog, :count).by(1)

      expect(ActionLog.last.action).to eq("dependency_down")
      expect(ActionLog.last.metadata["parent_id"]).to eq(parent.id)
    end

    it "skips paused dependents" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up", paused: true)
      create(:monitor_dependency, monitor: child, dependency: parent)

      described_class.cascade_down(parent)

      expect(child.reload.status).to eq("up")
    end

    it "handles multiple dependents" do
      parent = create(:uptime_monitor, status: "up")
      children = create_list(:uptime_monitor, 3, status: "up")
      children.each { |c| create(:monitor_dependency, monitor: c, dependency: parent) }

      expect {
        described_class.cascade_down(parent)
      }.to change(Incident, :count).by(3)

      children.each { |c| expect(c.reload).to be_dependency_affected }
    end
  end

  describe ".cascade_recovery" do
    it "restores dependents when no other parents are down" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)
      child.update!(status: "down", dependency_affected: true)
      child.incidents.create!(started_at: 5.minutes.ago)

      described_class.cascade_recovery(parent)

      expect(child.reload).not_to be_dependency_affected
      expect(child.status).to eq("up")
      expect(child.incidents.where(resolved_at: nil)).to be_empty
    end

    it "clears dependency_affected but keeps status down if own checks are failing" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)
      child.update!(status: "down", dependency_affected: true)
      create(:monitor_check, monitor: child, status: "down")

      described_class.cascade_recovery(parent)

      expect(child.reload).not_to be_dependency_affected
      expect(child.status).to eq("down")
    end

    it "does not restore if another parent is still down" do
      parent = create(:uptime_monitor, status: "up")
      other_parent = create(:uptime_monitor, status: "down")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)
      create(:monitor_dependency, monitor: child, dependency: other_parent)
      child.update!(status: "down", dependency_affected: true)

      described_class.cascade_recovery(parent)

      expect(child.reload).to be_dependency_affected
    end

    it "creates action logs on recovery" do
      parent = create(:uptime_monitor, status: "up")
      child = create(:uptime_monitor, status: "up")
      create(:monitor_dependency, monitor: child, dependency: parent)
      child.update!(status: "down", dependency_affected: true)

      expect {
        described_class.cascade_recovery(parent)
      }.to change(ActionLog, :count).by(1)

      expect(ActionLog.last.action).to eq("dependency_up")
    end
  end
end
