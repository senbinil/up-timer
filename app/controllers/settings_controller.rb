class SettingsController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:admin) }

  def show
    @account = current_account
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

  def toggle_email_notifications
    if Flipper.enabled?(:email_notifications)
      Flipper.disable(:email_notifications)
    else
      Flipper.enable(:email_notifications)
    end
    render partial: "email_notifications"
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
