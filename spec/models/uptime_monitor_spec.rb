require "rails_helper"

RSpec.describe UptimeMonitor, type: :model do
  describe "table_name" do
    it "uses monitors table" do
      expect(described_class.table_name).to eq("monitors")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:monitor_checks).dependent(:destroy) }
    it { is_expected.to have_many(:incidents).dependent(:destroy) }
    it { is_expected.to have_many(:alerts).dependent(:destroy) }
    it { is_expected.to have_many(:webhook_endpoint_monitors).dependent(:destroy).with_foreign_key(:monitor_id) }
    it { is_expected.to have_many(:webhook_endpoints).through(:webhook_endpoint_monitors) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:request_type).in_array(MonitorCheckService::SUPPORTED_METHODS) }
    it { is_expected.to allow_value(nil).for(:expected_status) }
    it { is_expected.to validate_numericality_of(:expected_status).only_integer.is_greater_than(0).is_less_than(600) }
    it { is_expected.to validate_length_of(:request_body).is_at_most(10_000) }
    it { is_expected.to validate_numericality_of(:down_threshold).only_integer.is_in(1..10) }
  end

  describe "scopes" do
    describe ".ranked" do
      it "orders by position descending then created_at descending" do
        a = create(:uptime_monitor, position: 1, created_at: 1.day.ago)
        b = create(:uptime_monitor, position: 2, created_at: Time.current)
        c = create(:uptime_monitor, position: 2, created_at: 1.hour.ago)

        expect(UptimeMonitor.ranked).to eq([ b, c, a ])
      end
    end

    describe ".top" do
      it "returns the top n monitors by rank" do
        create_list(:uptime_monitor, 5)
        expect(UptimeMonitor.top(3).count).to eq(3)
      end

      it "defaults to 3" do
        create_list(:uptime_monitor, 5)
        expect(UptimeMonitor.top.count).to eq(3)
      end
    end
  end

  describe ".fleet_stats" do
    it "returns operational when all monitors are up" do
      create(:uptime_monitor, status: "up")
      create(:uptime_monitor, status: "up")

      stats = UptimeMonitor.fleet_stats
      expect(stats[:status]).to eq("operational")
      expect(stats[:up_count]).to eq(2)
      expect(stats[:down_count]).to eq(0)
      expect(stats[:total]).to eq(2)
    end

    it "returns degraded when some monitors are down" do
      create(:uptime_monitor, status: "up")
      create(:uptime_monitor, status: "down")

      stats = UptimeMonitor.fleet_stats
      expect(stats[:status]).to eq("degraded")
    end

    it "returns down when all monitors are down" do
      create(:uptime_monitor, status: "down")

      stats = UptimeMonitor.fleet_stats
      expect(stats[:status]).to eq("down")
    end
  end

  describe ".all_tags" do
    it "returns all unique tags sorted" do
      create(:uptime_monitor, tags: [ "production", "critical" ])
      create(:uptime_monitor, tags: [ "staging", "critical" ])

      expect(UptimeMonitor.all_tags).to eq([ "critical", "production", "staging" ])
    end
  end

  describe "#tag_list" do
    it "joins tags with comma" do
      monitor = build(:uptime_monitor, tags: [ "a", "b" ])
      expect(monitor.tag_list).to eq("a, b")
    end

    it "returns empty string when no tags" do
      monitor = build(:uptime_monitor, tags: [])
      expect(monitor.tag_list).to eq("")
    end
  end

  describe "#tag_list=" do
    it "splits comma-separated string into tags" do
      monitor = build(:uptime_monitor)
      monitor.tag_list = "  alpha , beta , alpha "
      expect(monitor.tags).to eq(%w[alpha beta])
    end

    it "sets empty array for blank input" do
      monitor = build(:uptime_monitor)
      monitor.tag_list = ""
      expect(monitor.tags).to eq([])
    end
  end

  describe "#down?" do
    it "returns true when status is down" do
      monitor = build(:uptime_monitor, status: "down")
      expect(monitor).to be_down
    end

    it "returns false when status is not down" do
      monitor = build(:uptime_monitor, status: "up")
      expect(monitor).not_to be_down
    end
  end

  describe "#up?" do
    it "returns true when status is up" do
      monitor = build(:uptime_monitor, status: "up")
      expect(monitor).to be_up
    end
  end

  describe "#paused?" do
    it "returns true when paused is true" do
      monitor = build(:uptime_monitor, paused: true)
      expect(monitor).to be_paused
    end

    it "returns false when paused is false" do
      monitor = build(:uptime_monitor, paused: false)
      expect(monitor).not_to be_paused
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns unpaused monitors" do
        active = create(:uptime_monitor, paused: false)
        _paused = create(:uptime_monitor, paused: true)

        expect(UptimeMonitor.active).to contain_exactly(active)
      end
    end

    describe ".paused" do
      it "returns paused monitors" do
        _active = create(:uptime_monitor, paused: false)
        paused = create(:uptime_monitor, paused: true)

        expect(UptimeMonitor.paused).to contain_exactly(paused)
      end
    end
  end

  describe "#last_pause_log" do
    it "returns the most recent pause action log" do
      monitor = create(:uptime_monitor, paused: true)
      ActionLog.log(action: "paused", record: monitor, metadata: { name: monitor.name })

      expect(monitor.last_pause_log).to be_present
      expect(monitor.last_pause_log.action).to eq("paused")
    end

    it "returns nil when no pause log exists" do
      monitor = create(:uptime_monitor, paused: true)
      expect(monitor.last_pause_log).to be_nil
    end
  end

  describe "callbacks" do
    describe "after_create_commit :enqueue_first_check" do
      it "enqueues MonitorCheckJob after create" do
        allow(MonitorCheckJob).to receive(:perform_later)
        monitor = create(:uptime_monitor)

        expect(MonitorCheckJob).to have_received(:perform_later).with(monitor.id)
      end
    end
  end
end
