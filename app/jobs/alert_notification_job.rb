class AlertNotificationJob < ApplicationJob
  queue_as :default

  def perform(alert_id)
    return unless MailAdapter.configured?
    alert = Alert.find_by(id: alert_id)
    return unless alert
    return unless Flipper.enabled?(:email_notifications)

    # Only send email if the alert's trigger has email_notify enabled
    return unless alert.alert_trigger&.email_notify?

    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_down(email, alert).deliver_now
    end
  end
end
