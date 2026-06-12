class AlertNotificationJob < ApplicationJob
  queue_as :default

  def perform(alert_id)
    alert = Alert.find_by(id: alert_id)
    return unless alert

    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_down(email, alert).deliver_later
    end
  end
end
