require "rails_helper"

RSpec.describe "Public Status", type: :request do
  describe "GET /status/:token" do
    it "returns success for a valid token" do
      account = create(:account)
      get public_status_path(account.status_token)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for an invalid token" do
      get public_status_path("invalid-token")
      expect(response).to have_http_status(:not_found)
    end
  end
end
