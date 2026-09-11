require "rails_helper"

RSpec.describe "Admin Settings", type: :request do
  describe "authentication" do
    it "redirects unauthenticated requests" do
      get admin_settings_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization" do
    it "redirects non-admin users" do
      sign_in_collaborator
      get admin_settings_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /admin/settings" do
    before { sign_in_admin }

    it "returns success" do
      get admin_settings_path
      expect(response).to have_http_status(:ok)
    end

    it "renders site settings page" do
      get admin_settings_path
      expect(response.body).to include("Site Settings")
    end

    it "displays activity log entries" do
      admin = Account.find_by(role: "admin") || create(:account, role: "admin")
      ActionLog.log(
        action: :registration_toggled,
        record: admin,
        account: admin,
        metadata: { registration_enabled: true }
      )
      get admin_settings_path
      expect(response.body).to include("changed registration to")
    end
  end

  describe "PATCH /admin/settings" do
    before { sign_in_admin }

    context "with valid params" do
      it "disables registration" do
        patch admin_settings_path, params: {
          setting: { registration_enabled: "0" }
        }
        expect(SiteSetting.registration_enabled?).to be false
      end

      it "enables registration" do
        SiteSetting.set(:registration_enabled, "false")
        patch admin_settings_path, params: {
          setting: { registration_enabled: "1" }
        }
        expect(SiteSetting.registration_enabled?).to be true
      end

      it "creates an action log entry" do
        expect {
          patch admin_settings_path, params: {
            setting: { registration_enabled: "0" }
          }
        }.to change(ActionLog, :count).by(1)
      end
    end

    context "with turbo stream" do
      it "returns turbo stream response" do
        patch admin_settings_path, params: {
          setting: { registration_enabled: "0" }
        }, as: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end
end
