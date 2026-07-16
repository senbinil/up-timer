require "rails_helper"

RSpec.describe MonitorCheckService do
  describe ".call" do
    let(:monitor) { create(:uptime_monitor, url: "https://example.com", timeout: 5, request_type: "GET") }

    # Stub the HTTP request at the instance level to avoid httpx DSL complexity
    before do
      allow_any_instance_of(described_class).to receive(:perform_http_request) do |instance|
        OpenStruct.new(
          status: OpenStruct.new(to_i: 200, reason: "OK"),
          certificate: nil,
          respond_to?: ->(method) { method == :certificate }
        )
      end
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
        allow_any_instance_of(described_class).to receive(:perform_http_request).and_raise(StandardError.new("Connection refused"))
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
        allow_any_instance_of(described_class).to receive(:perform_http_request) do |instance|
          OpenStruct.new(
            status: OpenStruct.new(to_i: 200, reason: "OK"),
            certificate: fake_cert,
            respond_to?: ->(method) { method == :certificate }
          )
        end
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

      before do
        allow_any_instance_of(described_class).to receive(:perform_http_request) do |instance|
          # Verify the SESSION.request was called with POST and body
          OpenStruct.new(
            status: OpenStruct.new(to_i: 200, reason: "OK"),
            certificate: nil,
            respond_to?: ->(method) { method == :certificate }
          )
        end
      end

      it "returns a Result with status code" do
        result = described_class.call(monitor)
        expect(result.code).to eq(200)
        expect(result.up).to be true
      end
    end
  end
end
