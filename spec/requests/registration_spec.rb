require 'rails_helper'

RSpec.describe 'Registration', type: :request do
  let!(:admin) { Account.create!(email: 'admin@example.com', name: 'Admin', password: 'password123', role: 'admin', status: :verified) }

  before do
    # Ensure registration is enabled by default
    SiteSetting.set(:registration_enabled, 'true')
  end

  describe 'GET /create-account' do
    context 'when registration is enabled' do
      before { SiteSetting.set(:registration_enabled, 'true') }

      it 'shows the registration form' do
        get '/create-account'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Create Account')
      end
    end

    context 'when registration is disabled' do
      before { SiteSetting.set(:registration_enabled, 'false') }

      it 'shows the registration disabled message' do
        get '/create-account'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Registration Closed')
      end

      it 'does not show the registration form' do
        get '/create-account'
        expect(response.body).not_to include('Sign Up')
      end
    end
  end

  describe 'POST /create-account' do
    context 'when registration is enabled' do
      before { SiteSetting.set(:registration_enabled, 'true') }

      it 'allows account creation' do
        expect {
          post '/create-account', params: {
            email: 'newuser@example.com',
            name: 'New User',
            password: 'password123',
            confirm_password: 'password123',
            compliance: '1'
          }
        }.to change(Account, :count).by(1)
      end
    end

    context 'when registration is disabled' do
      before { SiteSetting.set(:registration_enabled, 'false') }

      it 'rejects account creation when disabled' do
        expect {
          post '/create-account', params: {
            email: 'newuser@example.com',
            name: 'New User',
            password: 'password123',
            compliance: '1'
          }
        }.not_to change(Account, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'Admin Settings' do
    before { sign_in(admin) }

    context 'when admin toggles registration' do
      it 'disables registration' do
        patch '/admin/settings', params: {
          setting: { registration_enabled: '0' }
        }
        expect(SiteSetting.registration_enabled?).to be false
        expect(response).to redirect_to(admin_settings_path)
      end

      it 'enables registration' do
        SiteSetting.set(:registration_enabled, 'false')

        patch '/admin/settings', params: {
          setting: { registration_enabled: '1' }
        }
        expect(SiteSetting.registration_enabled?).to be true
        expect(response).to redirect_to(admin_settings_path)
      end
    end
  end

  private

  def sign_in(account)
    post '/login', params: {
      email: account.email,
      password: 'password123'
    }
  end
end
