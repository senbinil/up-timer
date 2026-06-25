require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    it "redirects when not authenticated" do
      get dashboard_path
      expect(response).to have_http_status(:redirect)
    end

    it "returns success when authenticated" do
      sign_in
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "assigns instance variables" do
      sign_in
      create_list(:uptime_monitor, 3)
      create_list(:alert, 2, resolved: false)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard")
    end
  end
end
