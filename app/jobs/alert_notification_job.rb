class AlertNotificationJob < ApplicationJob
  queue_as :default

  def perform(alert_id)
    return unless MailAdapter.configured?
    alert = Alert.find_by(id: alert_id)
    return unless alert
    return unless Flipper.enabled?(:email_notifications)

    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_down(email, alert).deliver_later
    end
  end
end
