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

    broadcast_updates(monitor)
  end

  private

  def broadcast_updates(monitor)
    stats = compute_stats
    alert_counts = Alert.active.group(:severity).count
    new_alerts = Alert.where(created_at: 5.seconds.ago..).recent.to_a

    html = ApplicationController.render(
      template: "dashboard/broadcast",
      layout: false,
      assigns: {
        updated_nodes: [ monitor ],
        new_alerts: new_alerts,
        stats: stats,
        alert_counts: alert_counts
      }
    )

    Turbo::StreamsChannel.broadcast_stream_to("dashboard", content: html)
  end

  def compute_stats
    active_ids = UptimeMonitor.active.pluck(:id)
    fleet_base = UptimeMonitor.fleet_stats
    all_checks = MonitorCheck.where(monitor_id: active_ids)
    total_checks = all_checks.count
    up_checks = all_checks.where(status: "up").count

    fleet_base.merge(
      uptime: total_checks > 0 ? (up_checks.to_f / total_checks * 100).round(2) : 100,
      error_rate: total_checks > 0 ? ((total_checks - up_checks).to_f / total_checks * 100).round(2) : 0,
      paused_count: UptimeMonitor.paused.count
    )
  end
end
