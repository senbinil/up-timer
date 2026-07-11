class AlertIntegrationsController < ApplicationController
  layout "dashboard"
  before_action :authenticate
  before_action -> { require_role!(:admin) }

  def show
    @recipients = Recipient.ordered
    @triggers = AlertTrigger.ordered
    @new_recipient = Recipient.new
  end

  def search_recipients
    @recipients = Recipient.ordered
    @recipients = @recipients.where("email LIKE ? OR name LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    render partial: "recipients_list"
  end

  def create_recipient
    @recipient = Recipient.new(recipient_params)
    if @recipient.save
      redirect_to alert_integrations_path, notice: "Recipient added."
    else
      @recipients = Recipient.ordered
      @triggers = AlertTrigger.ordered
      @new_recipient = @recipient
      render :show, status: :unprocessable_entity
    end
  end

  def toggle_recipient
    @recipient = Recipient.find(params[:id])
    @recipient.toggle!(:active)
    @recipients = Recipient.ordered
    render partial: "recipients_list"
  end

  def toggle_trigger_email
    @trigger = AlertTrigger.find(params[:id])
    @trigger.toggle!(:email_notify)
    ActionLog.log(action: :toggled_email, record: @trigger, account: current_account,
                  metadata: { name: @trigger.name, email_notify: @trigger.email_notify })
    @triggers = AlertTrigger.ordered
    render partial: "triggers_list"
  end

  private

  def recipient_params
    params.require(:recipient).permit(:email)
  end
end
