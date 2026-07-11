require "rails_helper"

RSpec.describe "Alert Integrations", type: :request do
  describe "authentication" do
    it "redirects unauthenticated requests" do
      get alert_integrations_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization" do
    it "redirects non-admin users" do
      sign_in_collaborator
      get alert_integrations_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /alert_integrations" do
    it "returns success for admins" do
      sign_in_admin
      get alert_integrations_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /alert_integrations/search_recipients" do
    it "returns recipient list partial" do
      sign_in_admin
      create(:recipient, email: "test@example.com", name: "Test User")
      get search_recipients_alert_integrations_path, params: { q: "test" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /alert_integrations/recipients" do
    it "creates a recipient" do
      sign_in_admin
      expect {
        post recipients_alert_integrations_path, params: { recipient: { email: "new@example.com" } }
      }.to change(Recipient, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "renders show with errors on invalid data" do
      sign_in_admin
      post recipients_alert_integrations_path, params: { recipient: { email: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /alert_integrations/recipients/:id/toggle" do
    it "toggles recipient active status" do
      sign_in_admin
      recipient = create(:recipient, active: true)
      post toggle_recipient_alert_integrations_path(recipient)
      expect(recipient.reload.active).to be(false)
    end
  end

  describe "POST /alert_integrations/triggers/:id/toggle_email" do
    it "toggles trigger email_notify status" do
      sign_in_admin
      trigger = create(:alert_trigger, email_notify: false)
      expect {
        post toggle_trigger_email_alert_integrations_path(trigger)
      }.to change(ActionLog, :count).by(1)
      expect(trigger.reload.email_notify).to be(true)
    end
  end
end
