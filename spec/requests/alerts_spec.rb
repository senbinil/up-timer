require "rails_helper"

RSpec.describe "Alerts", type: :request do
  describe "authentication" do
    it "redirects unauthenticated requests" do
      get alerts_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /alerts" do
    it "returns success for authenticated users" do
      sign_in
      create_list(:alert, 3)
      get alerts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /alerts/:id" do
    it "shows an alert" do
      sign_in
      alert = create(:alert)
      get alert_path(alert)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /alerts/new" do
    it "is accessible to collaborators" do
      sign_in_collaborator
      get new_alert_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects viewers" do
      sign_in_viewer
      get new_alert_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /alerts" do
    let(:valid_params) do
      { alert: { severity: "warning", message: "Something happened", monitor_id: create(:uptime_monitor).id } }
    end

    it "creates an alert as a collaborator" do
      sign_in_collaborator
      expect {
        post alerts_path, params: valid_params
      }.to change(Alert, :count).by(1)
      expect(response).to redirect_to(alerts_path)
    end

    it "rejects invalid params" do
      sign_in_collaborator
      post alerts_path, params: { alert: { severity: "", message: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /alerts/:id/edit" do
    it "is accessible to collaborators" do
      sign_in_collaborator
      alert = create(:alert)
      get edit_alert_path(alert)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /alerts/:id" do
    it "updates the alert" do
      sign_in_collaborator
      alert = create(:alert, message: "Old message")
      patch alert_path(alert), params: { alert: { message: "New message" } }
      expect(alert.reload.message).to eq("New message")
      expect(response).to redirect_to(alerts_path)
    end
  end

  describe "DELETE /alerts/:id" do
    it "deletes the alert" do
      sign_in_collaborator
      alert = create(:alert)
      expect {
        delete alert_path(alert)
      }.to change(Alert, :count).by(-1)
      expect(response).to redirect_to(alerts_path)
    end
  end

  describe "POST /alerts/:id/resolve" do
    it "resolves the alert" do
      sign_in
      alert = create(:alert, resolved: false)
      post resolve_alert_path(alert)
      expect(alert.reload).to be_resolved
    end

    it "creates an action log" do
      account = sign_in
      alert = create(:alert, resolved: false)
      expect {
        post resolve_alert_path(alert)
      }.to change(ActionLog, :count).by(1)
      log = ActionLog.last
      expect(log.action).to eq("resolved")
      expect(log.account).to eq(account)
    end
  end
end
