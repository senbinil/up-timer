class SettingsController < ApplicationController
  layout "dashboard"
  before_action :authenticate

  def show
    @preference = current_account.preference
  end

  def update
    @preference = current_account.preference
    if @preference.update(preference_params)
      redirect_to settings_path, notice: "Settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def authenticate
    rodauth.require_account
  end

  def current_account
    Account.find(rodauth.session_value)
  end

  def preference_params
    params.require(:user_preference).permit(:dashboard_limit)
  end
end
