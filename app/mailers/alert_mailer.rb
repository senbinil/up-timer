class AlertMailer < ApplicationMailer
  def alert_down(recipient_email, alert)
    @alert = alert
    @monitor = alert.monitor
    mail to: recipient_email,
         subject: "[DOWN] #{alert.severity.upcase} — #{@monitor&.name || "System"} is unreachable"
  end

  def alert_recovered(recipient_email, monitor_id)
    @monitor = UptimeMonitor.find(monitor_id)
    mail to: recipient_email,
         subject: "[RECOVERED] #{@monitor.name} is back online"
  end
end
