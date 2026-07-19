require "rails_helper"

RSpec.describe MonitorCheckService do
  describe ".call" do
    let(:monitor) { create(:uptime_monitor, url: "https://example.com", timeout: 5, request_type: "GET") }

    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPResponse, code: "200", message: "OK") }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)
      allow(http).to receive(:respond_to?).with(:write_timeout=).and_return(false)
      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:peer_cert).and_return(nil)
    end

    it "returns a Result with status code and message" do
      result = described_class.call(monitor)
      expect(result.code).to eq(200)
      expect(result.message).to eq("OK")
      expect(result.up).to be true
    end

    it "records the request duration in milliseconds" do
      result = described_class.call(monitor)
      expect(result.duration).to be_a(Float)
      expect(result.duration).to be >= 0
    end

    context "when the monitor has an expected status" do
      let(:monitor) { create(:uptime_monitor, url: "https://example.com", timeout: 5, request_type: "GET", expected_status: 201) }

      it "marks as down if the actual status does not match" do
        result = described_class.call(monitor)
        expect(result.up).to be false
      end
    end

    context "when the request fails" do
      before do
        allow(http).to receive(:request).and_raise(StandardError.new("Connection refused"))
      end

      it "returns a Result with no code and up: false" do
        result = described_class.call(monitor)
        expect(result.code).to be_nil
        expect(result.up).to be false
        expect(result.message).to eq("Connection refused")
        expect(result.duration).to eq(0)
      end
    end

    context "when the response includes SSL certificate info" do
      let(:fake_cert) do
        instance_double(
          OpenSSL::X509::Certificate,
          not_before: 1.year.ago,
          not_after: 1.year.from_now,
          issuer: instance_double(OpenSSL::X509::Name, to_s: "/CN=Test Issuer"),
          subject: instance_double(OpenSSL::X509::Name, to_s: "/CN=example.com")
        )
      end

      before do
        allow(http).to receive(:peer_cert).and_return(fake_cert)
      end

      it "extracts SSL validity and issuer info" do
        result = described_class.call(monitor)
        expect(result.ssl_valid).to be true
        expect(result.ssl_issuer).to eq("/CN=Test Issuer")
        expect(result.ssl_subject).to eq("/CN=example.com")
        expect(result.ssl_expires_at).to be_present
      end
    end

    context "with POST and request body" do
      let(:monitor) { create(:uptime_monitor, url: "https://example.com/api", timeout: 5, request_type: "POST", request_body: '{"key":"value"}') }

      it "returns a Result with status code" do
        result = described_class.call(monitor)
        expect(result.code).to eq(200)
        expect(result.up).to be true
      end
    end
  end
end
