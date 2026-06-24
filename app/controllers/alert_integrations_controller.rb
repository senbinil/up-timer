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
      @recipients = Recipient.ordered
      render partial: "recipients_list"
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

  def toggle_trigger
    @trigger = AlertTrigger.find(params[:id])
    @trigger.toggle!(:active)
    ActionLog.log(action: :toggled, record: @trigger, account: current_account,
                  metadata: { name: @trigger.name, active: @trigger.active, severity: @trigger.severity })
    @triggers = AlertTrigger.ordered
    render partial: "triggers_list"
  end

  private

  def recipient_params
    params.require(:recipient).permit(:email)
  end
end
