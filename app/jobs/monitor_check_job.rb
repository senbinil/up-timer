class MonitorCheckJob < ApplicationJob
  queue_as :default

  def perform(monitor_id)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor
    return if monitor.paused?

    result = MonitorCheckService.call(monitor)
    status = result.up ? "up" : "down"

    monitor.monitor_checks.create!(
      status: status,
      response_time: result.duration,
      status_code: result.code,
      checked_at: Time.current,
      ssl_valid: result.ssl_valid,
      ssl_expires_at: result.ssl_expires_at,
      ssl_issuer: result.ssl_issuer,
      ssl_subject: result.ssl_subject
    )

    MonitorStatusService.call(monitor)
    monitor.reload

    new_alerts = Alert.where(created_at: 5.seconds.ago..).recent.to_a
    DashboardBroadcastService.call(updated_nodes: monitor, new_alerts: new_alerts)
  end
end
