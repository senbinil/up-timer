require "rails_helper"

RSpec.describe "Authentication flows", type: :request do
  describe "with email configured (default test mode)" do
    # MailAdapter.configured? returns true (configured = !Rails.env.production?).
    # Rodauth loads verify_account feature; accounts are created unverified.

    describe "POST /create-account" do
      let(:valid_params) do
        {
          email: "newuser@example.com",
          name: "New User",
          password: "password123",
          confirm_password: "password123",
          compliance: "1"
        }
      end

      it "creates a new account as unverified" do
        expect {
          post "/create-account", params: valid_params
        }.to change(Account, :count).by(1)

        account = Account.find_by(email: "newuser@example.com")
        expect(account.status).to eq("unverified")
      end

      it "sets name and default viewer role" do
        post "/create-account", params: valid_params
        account = Account.find_by(email: "newuser@example.com")
        expect(account.name).to eq("New User")
        expect(account.role).to eq("viewer")
      end

      it "assigns admin role for admin emails" do
        stub_const("ADMIN_EMAILS", [ "admin@example.com" ])
        post "/create-account", params: valid_params.merge(email: "admin@example.com")
        account = Account.find_by(email: "admin@example.com")
        expect(account.role).to eq("admin")
      end

      it "redirects after creation" do
        post "/create-account", params: valid_params
        expect(response).to have_http_status(:redirect)
      end

      it "returns error when name is missing" do
        post "/create-account", params: valid_params.merge(name: "")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be present")
      end

      it "returns error when compliance is not accepted" do
        post "/create-account", params: valid_params.merge(compliance: "0")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be accepted")
      end

      it "returns error when email is already taken" do
        create(:account, email: "newuser@example.com")
        post "/create-account", params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /create-account" do
      it "shows the registration form" do
        get "/create-account"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("email")
      end
    end

    describe "GET /login" do
      it "shows the login form" do
        get "/login"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("email")
      end

      it "redirects authenticated users to dashboard" do
        sign_in
        get "/login"
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "POST /login" do
      let!(:account) { create(:account) }

      it "logs in with valid credentials" do
        post "/login", params: { email: account.email, password: "password" }
        expect(response).to redirect_to(dashboard_path)
      end

      it "rejects invalid password with 401" do
        post "/login", params: { email: account.email, password: "wrong" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "POST /logout" do
      it "logs out and redirects to root" do
        sign_in
        post "/logout"
        expect(response).to redirect_to(root_path)
      end
    end

    describe "password reset" do
      let!(:account) { create(:account) }

      describe "POST /reset-password-request" do
        it "redirects with success for existing email" do
          post "/reset-password-request", params: { email: account.email }
          expect(response).to have_http_status(:redirect)
        end

        it "does not reveal if email does not exist (returns 401)" do
          post "/reset-password-request", params: { email: "nonexistent@example.com" }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "GET /reset-password" do
        it "redirects to login page without a valid key" do
          get "/reset-password"
          expect(response).to have_http_status(:redirect)
        end
      end

      describe "POST /reset-password" do
        it "redirects to login when key is invalid" do
          post "/reset-password", params: { key: "invalid-key", password: "newpass123", confirm_password: "newpass123" }
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    describe "account verification" do
      describe "GET /verify-account" do
        it "redirects when key is invalid" do
          get "/verify-account", params: { key: "invalid-key" }
          expect(response).to have_http_status(:redirect)
        end
      end

      describe "POST /verify-account-resend" do
        let!(:account) { create(:account, status: :unverified) }

        it "redirects with success" do
          post "/verify-account-resend", params: { email: account.email }
          expect(response).to have_http_status(:redirect)
        end
      end

      describe "GET /verify-account-resend" do
        it "shows the resend form" do
          get "/verify-account-resend"
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "without email configured", :without_email do
    # Rails.application.config.email_configured set to false at runtime.
    # Rodauth features (verify_account) are loaded at class load time, but
    # the after_create_account hook auto-verifies accounts at runtime.
    # verify-account routes still exist (loaded at boot) but the
    # after_create_account hook sets status to verified.

    before do
      @_original_email_configured = Rails.application.config.email_configured
      Rails.application.config.email_configured = false
    end

    after do
      Rails.application.config.email_configured = @_original_email_configured
    end

    describe "POST /create-account" do
      let(:valid_params) do
        {
          email: "auto-verify@example.com",
          name: "Auto Verify",
          password: "password123",
          confirm_password: "password123",
          compliance: "1"
        }
      end

      it "creates a new account as verified (auto-verified by after_create hook)" do
        post "/create-account", params: valid_params
        account = Account.find_by(email: "auto-verify@example.com")
        expect(account).to be_verified
      end

      it "sets name and default viewer role" do
        post "/create-account", params: valid_params
        account = Account.find_by(email: "auto-verify@example.com")
        expect(account.name).to eq("Auto Verify")
        expect(account.role).to eq("viewer")
      end

      it "redirects after creation" do
        post "/create-account", params: valid_params
        expect(response).to have_http_status(:redirect)
      end

      it "returns error when name is missing" do
        post "/create-account", params: valid_params.merge(name: "")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be present")
      end

      it "returns error when compliance is not accepted" do
        post "/create-account", params: valid_params.merge(compliance: "0")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be accepted")
      end
    end

    describe "GET /login" do
      it "shows the login form" do
        get "/login"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("email")
      end
    end

    describe "POST /login" do
      let!(:account) { create(:account) }

      it "logs in with valid credentials" do
        post "/login", params: { email: account.email, password: "password" }
        expect(response).to redirect_to(dashboard_path)
      end

      it "rejects invalid password with 401" do
        post "/login", params: { email: account.email, password: "wrong" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "POST /logout" do
      it "logs out and redirects to root" do
        sign_in
        post "/logout"
        expect(response).to redirect_to(root_path)
      end
    end

    describe "password reset" do
      let!(:account) { create(:account) }

      describe "POST /reset-password-request" do
        it "redirects with success for existing email" do
          post "/reset-password-request", params: { email: account.email }
          expect(response).to have_http_status(:redirect)
        end

        it "does not reveal if email does not exist (returns 401)" do
          post "/reset-password-request", params: { email: "nonexistent@example.com" }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
