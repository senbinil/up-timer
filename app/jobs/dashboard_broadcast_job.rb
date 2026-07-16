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

    # 4. Broadcast dashboard changes
    DashboardBroadcastService.call(updated_nodes: updated_nodes, new_alerts: new_alerts)

    # 5. Broadcast to public status page (only if any public-listed nodes changed)
    public_ids = UptimeMonitor.public_listed.where(id: checked_monitor_ids).pluck(:id)
    if public_ids.any? || new_alerts.any?
      public_nodes = UptimeMonitor.where(id: public_ids).includes(:monitor_checks)
      StatusPageBroadcastService.call(updated_nodes: public_nodes, new_alerts: new_alerts)
    end

    # 6. Advance cursor
    Rails.cache.write(CURSOR_KEY, Time.current)
  end
end
