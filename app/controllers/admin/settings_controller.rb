module Admin
  class SettingsController < ApplicationController
    layout "dashboard"
    before_action :authenticate
    before_action -> { require_role!(:admin) }
    before_action :load_action_logs, only: :show
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_concurrent_change

    def show
      @registration_enabled = SiteSetting.registration_enabled?
    end

    def update
      setting = params.require(:setting).permit(:registration_enabled)
      @changed = false

      if %w[true false 1 0].include?(setting[:registration_enabled])
        new_value = ActiveModel::Type::Boolean.new.cast(setting[:registration_enabled]).to_s
        if SiteSetting.registration_enabled?.to_s != new_value
          SiteSetting.set(:registration_enabled, new_value)
          ActionLog.log(
            action: :registration_toggled,
            record: current_account,
            account: current_account,
            metadata: { "registration_enabled" => SiteSetting.registration_enabled?.to_s }
          )
          @changed = true
        end
      end

      @registration_enabled = SiteSetting.registration_enabled?
      load_action_logs

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_settings_path, notice: @changed ? "Settings updated." : "No changes made." }
      end
    end

    private

    def load_action_logs
      @action_logs = ActionLog.where(action: :registration_toggled).includes(:account).recent.limit(5)
    end

    def handle_concurrent_change
      @registration_enabled = SiteSetting.registration_enabled?
      load_action_logs
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("admin_settings_registration", partial: "admin/settings/registration_card") }
        format.html { redirect_to admin_settings_path, alert: "A concurrent change occurred. Please try again." }
      end
    end
  end
end
