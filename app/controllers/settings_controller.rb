class SettingsController < ApplicationController
  layout "dashboard"
  before_action :authenticate

  def show
    @account = current_account
    @account.update!(status_token: SecureRandom.urlsafe_base64(24)) if @account.status_token.blank?
    @preference = current_account.preference
  end

  def update
    @account = current_account
    @preference = current_account.preference

    updated = @preference.update(preference_params)
    updated &= @account.update(name: params[:account][:name]) if params[:account][:name].present?

    if updated
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_path, notice: "Settings updated." }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.require(:user_preference).permit(:dashboard_limit)
  end
end
