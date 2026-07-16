require "rails_helper"

RSpec.describe FleetStatsService do
  describe ".call" do
    context "with no monitors" do
      it "returns default operational stats" do
        stats = described_class.call

        expect(stats).to match(
          status: "operational",
          up_count: 0,
          down_count: 0,
          total: 0,
          uptime: 100,
          error_rate: 0,
          paused_count: 0
        )
      end
    end

    context "with all monitors up" do
      before do
        create(:uptime_monitor, status: "up")
        create(:uptime_monitor, status: "up")
      end

      it "returns operational status" do
        stats = described_class.call
        expect(stats[:status]).to eq("operational")
        expect(stats[:up_count]).to eq(2)
        expect(stats[:down_count]).to eq(0)
        expect(stats[:total]).to eq(2)
      end

      it "computes uptime percentage from monitor_checks" do
        create(:monitor_check, monitor: UptimeMonitor.first, status: "up")
        create(:monitor_check, monitor: UptimeMonitor.last, status: "up")

        stats = described_class.call
        expect(stats[:uptime]).to eq(100.0)
        expect(stats[:error_rate]).to eq(0.0)
      end
    end

    context "with mixed status monitors" do
      before do
        create(:uptime_monitor, status: "up")
        create(:uptime_monitor, status: "down")
      end

      it "returns degraded status" do
        stats = described_class.call
        expect(stats[:status]).to eq("degraded")
        expect(stats[:up_count]).to eq(1)
        expect(stats[:down_count]).to eq(1)
        expect(stats[:total]).to eq(2)
      end

      it "computes error rate correctly" do
        up_monitor = UptimeMonitor.find_by(status: "up")
        down_monitor = UptimeMonitor.find_by(status: "down")
        create(:monitor_check, monitor: up_monitor, status: "up")
        create(:monitor_check, monitor: down_monitor, status: "down")

        stats = described_class.call
        expect(stats[:error_rate]).to eq(50.0)
      end
    end

    context "with all monitors down" do
      before do
        create(:uptime_monitor, status: "down")
      end

      it "returns down status" do
        stats = described_class.call
        expect(stats[:status]).to eq("down")
        expect(stats[:up_count]).to eq(0)
        expect(stats[:down_count]).to eq(1)
      end
    end

    context "with paused monitors" do
      before do
        create(:uptime_monitor, status: "up", paused: true)
        create(:uptime_monitor, status: "up", paused: false)
      end

      it "counts paused monitors separately" do
        stats = described_class.call
        expect(stats[:paused_count]).to eq(1)
        expect(stats[:total]).to eq(2)
      end
    end

    context "with a custom scope" do
      before do
        create(:uptime_monitor, status: "up", public_listed: true)
        create(:uptime_monitor, status: "down", public_listed: false)
      end

      it "scopes stats to public_listed monitors" do
        stats = described_class.call(UptimeMonitor.public_listed)
        expect(stats[:total]).to eq(1)
        expect(stats[:up_count]).to eq(1)
        expect(stats[:status]).to eq("operational")
      end
    end
  end
end
