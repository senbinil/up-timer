class DashboardBroadcastJob < ApplicationJob
  queue_as :dashboard_broadcast

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

    # 4. Broadcast and advance cursor
    DashboardBroadcastService.call(updated_nodes: updated_nodes, new_alerts: new_alerts)
    StatusPageBroadcastService.call(updated_nodes: updated_nodes, new_alerts: new_alerts)
    Rails.cache.write(CURSOR_KEY, Time.current)
  end
end
