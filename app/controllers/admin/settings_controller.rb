module Admin
  class SettingsController < ApplicationController
    layout "dashboard"
    before_action :authenticate
    before_action -> { require_role!(:admin) }

    def show
      @registration_enabled = SiteSetting.registration_enabled?
      @action_logs = ActionLog.where(action: "registration_toggled").includes(:account).recent.limit(5)
    end

    def update
      setting = params.require(:setting).permit(:registration_enabled)
      if setting[:registration_enabled].present?
        new_value = setting[:registration_enabled] == "1" ? "true" : "false"
        SiteSetting.set(:registration_enabled, new_value)
        ActionLog.log(
          action: :registration_toggled,
          record: current_account,
          account: current_account,
          metadata: { registration_enabled: SiteSetting.registration_enabled? }
        )
      end

      @registration_enabled = SiteSetting.registration_enabled?
      @action_logs = ActionLog.where(action: "registration_toggled").includes(:account).recent.limit(5)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_settings_path, notice: "Settings updated." }
      end
    end
  end
end
