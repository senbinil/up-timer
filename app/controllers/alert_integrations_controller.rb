class AlertIntegrationsController < ApplicationController
  layout "dashboard"
  before_action :authenticate

  def show
    @recipients = Recipient.ordered
    @triggers = AlertTrigger.ordered
    @new_recipient = Recipient.new
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
    @triggers = AlertTrigger.ordered
    render partial: "triggers_list"
  end

  private

  def authenticate
    rodauth.require_account
  end

  def recipient_params
    params.require(:recipient).permit(:email)
  end
end
