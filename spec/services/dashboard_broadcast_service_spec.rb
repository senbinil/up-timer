require "rails_helper"

RSpec.describe DashboardBroadcastService do
  describe ".call" do
    let(:node) { create(:uptime_monitor, status: "up") }
    let(:alert) { create(:alert) }

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_stream_to)
    end

    it "broadcasts to the dashboard channel" do
      described_class.call(updated_nodes: [ node ], new_alerts: [ alert ])
      expect(Turbo::StreamsChannel).to have_received(:broadcast_stream_to).with("dashboard", content: kind_of(String))
    end

    it "includes node replacement streams" do
      described_class.call(updated_nodes: [ node ])
      expect(Turbo::StreamsChannel).to have_received(:broadcast_stream_to) do |_channel, content:|
        expect(content).to include('turbo-stream action="replace"')
        expect(content).to include(ERB::Util.html_escape(node.name))
      end
    end

    it "includes alert prepend streams" do
      described_class.call(updated_nodes: [], new_alerts: [ alert ])
      expect(Turbo::StreamsChannel).to have_received(:broadcast_stream_to) do |_channel, content:|
        expect(content).to include('turbo-stream action="prepend"')
        expect(content).to include("recent_alerts")
      end
    end

    it "includes fleet status replacement" do
      described_class.call(updated_nodes: [ node ])
      expect(Turbo::StreamsChannel).to have_received(:broadcast_stream_to) do |_channel, content:|
        expect(content).to include("fleet_status")
        expect(content).to include("Global Fleet Status")
      end
    end

    context "with no updates" do
      it "still broadcasts fleet status" do
        described_class.call(updated_nodes: [], new_alerts: [])
        expect(Turbo::StreamsChannel).to have_received(:broadcast_stream_to)
      end
    end
  end
end
