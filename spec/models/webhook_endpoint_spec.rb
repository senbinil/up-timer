require "rails_helper"

RSpec.describe WebhookEndpoint, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:webhook_endpoint_monitors).dependent(:destroy) }
    it { is_expected.to have_many(:monitors).through(:webhook_endpoint_monitors) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to allow_value("https://example.com/hooks").for(:url) }
    it { is_expected.to allow_value("http://example.com/hooks").for(:url) }
    it { is_expected.not_to allow_value("ftp://example.com").for(:url) }
    it { is_expected.not_to allow_value("not-a-url").for(:url) }
    it { is_expected.not_to allow_value("").for(:url) }
  end

  describe "token handling" do
    it "stores the provided token as-is" do
      endpoint = described_class.create!(url: "https://example.com/hooks", token: "my-secret-token-123")
      expect(endpoint.token).to eq("my-secret-token-123")
    end

    it "sets token_prefix to first 8 chars of the provided token" do
      endpoint = described_class.create!(url: "https://example.com/hooks", token: "my-secret-token-123")
      expect(endpoint.token_prefix).to eq("my-secre")
    end
  end

  describe "#masked_token" do
    it "shows first 8 chars followed by ... for long tokens" do
      endpoint = build(:webhook_endpoint, token: "abcdefghijklmnop")
      expect(endpoint.masked_token).to eq("abcdefgh...")
    end

    it "returns *** for short tokens" do
      endpoint = build(:webhook_endpoint, token: "short")
      expect(endpoint.masked_token).to eq("***")
    end

    it "returns empty string when token is blank" do
      endpoint = build(:webhook_endpoint, token: "")
      expect(endpoint.masked_token).to eq("")
    end
  end

  describe "#masked_url" do
    it "masks the path of the URL" do
      endpoint = build(:webhook_endpoint, url: "https://example.com/secret-path")
      expect(endpoint.masked_url).to eq("https://example.com/***")
    end

    it "includes port when non-standard" do
      endpoint = build(:webhook_endpoint, url: "https://example.com:8443/events")
      expect(endpoint.masked_url).to eq("https://example.com:8443/***")
    end
  end

  describe "scope .active" do
    it "includes active endpoints" do
      active = create(:webhook_endpoint, active: true)
      expect(described_class.active).to include(active)
    end

    it "excludes inactive endpoints" do
      inactive = create(:webhook_endpoint, active: false)
      expect(described_class.active).not_to include(inactive)
    end
  end
end
