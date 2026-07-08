class HomeController < ApplicationController
  layout "public_status"

  def show
    @nodes = UptimeMonitor.public_listed.ranked.includes(:monitor_checks)
    @total_nodes = UptimeMonitor.count
    @public_listed_count = @nodes.size

    total = @public_listed_count
    up_count = @nodes.where(status: "up").size
    down_count = total - up_count

    @stats = {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
      total: total
    }

    @last_resolved = Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
    @alert_counts = Alert.active.group(:severity).count
    @recent_alerts = Alert.recent.limit(5)
  end
end
