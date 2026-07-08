require "rails_helper"

RSpec.describe "Settings", type: :request do
  describe "authentication" do
    it "redirects unauthenticated requests" do
      get settings_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /settings" do
    it "returns success for authenticated users" do
      sign_in
      get settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /settings" do
    it "updates dashboard limit" do
      account = sign_in
      patch settings_path, params: { user_preference: { dashboard_limit: 5 }, account: { name: account.name } }
      expect(account.preference.reload.dashboard_limit).to eq(5)
    end

    it "updates account name" do
      account = sign_in
      patch settings_path, params: { account: { name: "New Name" }, user_preference: { dashboard_limit: 3 } }
      expect(account.reload.name).to eq("New Name")
    end

    it "updates successfully with valid params" do
      account = sign_in
      patch settings_path, params: { user_preference: { dashboard_limit: 10 }, account: { name: account.name } }
      expect(response).to redirect_to(settings_path)
    end
  end
end
