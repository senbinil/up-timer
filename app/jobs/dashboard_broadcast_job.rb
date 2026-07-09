class DashboardBroadcastJob < ApplicationJob
  queue_as :default

  CURSOR_KEY = "dashboard:last_broadcast_at"
  FALLBACK_WINDOW = 5.seconds

  def perform
    cursor = Rails.cache.read(CURSOR_KEY) || FALLBACK_WINDOW.ago

    # 1. Find recently checked nodes
    checked_monitor_ids = MonitorCheck
      .where(checked_at: cursor..)
      .distinct
      .pluck(:monitor_id)

    # 2. Find new alerts
    new_alerts = Alert
      .where(created_at: cursor..)
      .recent
      .to_a

    # Skip if nothing changed
    return if checked_monitor_ids.empty? && new_alerts.empty?

    # 3. Preload changed nodes (avoid N+1 in template)
    updated_nodes = UptimeMonitor
      .where(id: checked_monitor_ids)
      .includes(:monitor_checks)

    # 4. Compute fresh fleet stats (same shape as DashboardController#fleet_stats)
    active_ids = UptimeMonitor.active.pluck(:id)
    fleet_base = UptimeMonitor.fleet_stats
    all_checks = MonitorCheck.where(monitor_id: active_ids)
    total_checks = all_checks.count
    up_checks = all_checks.where(status: "up").count
    stats = fleet_base.merge(
      uptime: total_checks > 0 ? (up_checks.to_f / total_checks * 100).round(2) : 100,
      error_rate: total_checks > 0 ? ((total_checks - up_checks).to_f / total_checks * 100).round(2) : 0,
      paused_count: UptimeMonitor.paused.count
    )
    alert_counts = Alert.active.group(:severity).count

    # 5. Render a single combined Turbo Stream
    html = ApplicationController.render(
      template: "dashboard/broadcast",
      layout: false,
      assigns: {
        updated_nodes: updated_nodes,
        new_alerts: new_alerts,
        stats: stats,
        alert_counts: alert_counts
      }
    )

    # 6. Broadcast as one message
    Turbo::StreamsChannel.broadcast_stream_to("dashboard", html)

    # 7. Advance cursor
    Rails.cache.write(CURSOR_KEY, Time.current)
  end
end
