require "rails_helper"

RSpec.describe "Nodes", type: :request do
  let(:monitor) { create(:uptime_monitor) }

  describe "authentication" do
    it "redirects unauthenticated requests" do
      get nodes_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /nodes" do
    it "returns success for authenticated users" do
      sign_in
      create_list(:uptime_monitor, 3)
      get nodes_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /nodes/new" do
    it "is accessible to collaborators" do
      sign_in_collaborator
      get new_node_path
      expect(response).to have_http_status(:ok)
    end

    it "is inaccessible to viewers" do
      sign_in_viewer
      get new_node_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /nodes" do
    let(:valid_params) do
      { uptime_monitor: { name: "New Monitor", url: "https://example.com", check_interval: 60, timeout: 30 } }
    end

    it "creates a monitor as a collaborator" do
      sign_in_collaborator
      expect {
        post nodes_path, params: valid_params
      }.to change(UptimeMonitor, :count).by(1)
      expect(response).to redirect_to(nodes_path)
    end

    it "rejects invalid request_type" do
      sign_in_collaborator
      post nodes_path, params: { uptime_monitor: { name: "Test", url: "https://example.com", check_interval: 60, timeout: 30, request_type: "INVALID" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /nodes/:id" do
    it "shows a monitor" do
      sign_in
      create(:monitor_check, monitor: monitor)
      get node_path(monitor)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /nodes/:id/edit" do
    it "is accessible to collaborators" do
      sign_in_collaborator
      get edit_node_path(monitor)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /nodes/:id" do
    it "updates the monitor" do
      sign_in_collaborator
      patch node_path(monitor), params: { uptime_monitor: { name: "Updated" } }
      expect(monitor.reload.name).to eq("Updated")
      expect(response).to redirect_to(node_path(monitor))
    end

    it "rejects invalid request_type" do
      sign_in_collaborator
      patch node_path(monitor), params: { uptime_monitor: { request_type: "INVALID" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /nodes/:id" do
    it "deletes the monitor" do
      sign_in_collaborator
      monitor # ensure creation
      expect {
        delete node_path(monitor)
      }.to change(UptimeMonitor, :count).by(-1)
      expect(response).to redirect_to(nodes_path)
    end
  end

  describe "POST /nodes/:id/move_up" do
    it "moves the monitor up" do
      sign_in_collaborator
      expect {
        post move_up_node_path(monitor)
      }.to change { monitor.reload.position }.by(1)
      expect(response).to redirect_to(nodes_path)
    end
  end

  describe "POST /nodes/:id/move_down" do
    it "moves the monitor down" do
      sign_in_collaborator
      expect {
        post move_down_node_path(monitor)
      }.to change { monitor.reload.position }.by(-1)
      expect(response).to redirect_to(nodes_path)
    end
  end

  describe "PATCH /nodes/:id/assign_tag" do
    it "adds a tag to the monitor" do
      sign_in_collaborator
      patch assign_tag_node_path(monitor), params: { tag: "production" }
      expect(monitor.reload.tags).to include("production")
    end

    it "removes an existing tag" do
      sign_in_collaborator
      monitor.update!(tags: [ "production" ])
      patch assign_tag_node_path(monitor), params: { tag: "production" }
      expect(monitor.reload.tags).not_to include("production")
    end

    it "returns bad_request when tag is blank" do
      sign_in_collaborator
      patch assign_tag_node_path(monitor), params: { tag: "" }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /nodes/:id/pause" do
    it "pauses the monitor" do
      sign_in_admin
      post pause_node_path(monitor)
      expect(monitor.reload).to be_paused
    end

    it "creates an action log" do
      sign_in_admin
      expect {
        post pause_node_path(monitor)
      }.to change(ActionLog, :count).by(1)
      expect(ActionLog.last.action).to eq("paused")
    end

    it "is inaccessible to collaborators" do
      sign_in_collaborator
      post pause_node_path(monitor)
      expect(response).to have_http_status(:redirect)
      expect(monitor.reload).not_to be_paused
    end

    it "redirects to show page on HTML request" do
      sign_in_admin
      post pause_node_path(monitor)
      expect(response).to redirect_to(node_path(monitor))
    end
  end

  describe "POST /nodes/:id/resume" do
    it "resumes the monitor" do
      monitor.update!(paused: true)
      sign_in_admin
      post resume_node_path(monitor)
      expect(monitor.reload).not_to be_paused
    end

    it "creates an action log" do
      monitor.update!(paused: true)
      sign_in_admin
      expect {
        post resume_node_path(monitor)
      }.to change(ActionLog, :count).by(1)
      expect(ActionLog.last.action).to eq("resumed")
    end

    it "is inaccessible to collaborators" do
      monitor.update!(paused: true)
      sign_in_collaborator
      post resume_node_path(monitor)
      expect(response).to have_http_status(:redirect)
      expect(monitor.reload).to be_paused
    end
  end
end
