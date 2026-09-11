require 'rails_helper'

RSpec.describe 'Registration', type: :request do
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

      it 'redirects to registration page when disabled' do
        expect {
          post '/create-account', params: {
            email: 'newuser@example.com',
            name: 'New User',
            password: 'password123',
            compliance: '1'
          }
        }.not_to change(Account, :count)
        expect(response).to redirect_to('/create-account')
      end
    end
  end
end
