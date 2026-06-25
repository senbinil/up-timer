require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "authentication" do
    it "redirects unauthenticated requests" do
      get users_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization" do
    it "redirects non-admin users" do
      sign_in_collaborator
      get users_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /users" do
    it "returns success for admin users" do
      sign_in_admin
      create_list(:account, 3)
      get users_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /users/:id/update_role" do
    let(:target_user) { create(:account, role: "viewer") }

    it "updates the user role" do
      sign_in_admin
      patch update_role_user_path(target_user), params: { role: "collaborator" }
      expect(target_user.reload.role).to eq("collaborator")
      expect(response).to redirect_to(users_path)
    end

    it "creates an action log" do
      sign_in_admin
      expect {
        patch update_role_user_path(target_user), params: { role: "admin" }
      }.to change(ActionLog, :count).by(1)
      log = ActionLog.last
      expect(log.action).to eq("role_changed")
      expect(log.metadata.symbolize_keys).to include(target: target_user.email, new_role: "admin")
    end

    it "prevents changing own role" do
      admin = sign_in_admin
      patch update_role_user_path(admin), params: { role: "viewer" }
      expect(response).to redirect_to(users_path)
      expect(flash[:alert]).to be_present
      expect(admin.reload.role).to eq("admin")
    end

    it "rejects invalid role" do
      sign_in_admin
      patch update_role_user_path(target_user), params: { role: "superadmin" }
      expect(response).to redirect_to(users_path)
      expect(target_user.reload.role).to eq("viewer")
    end
  end
end
