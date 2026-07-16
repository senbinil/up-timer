class HomeController < ApplicationController
  layout "public_status"

  def show
    @nodes = UptimeMonitor.public_listed.ranked.includes(:monitor_checks)
    @total_nodes = UptimeMonitor.count
    @public_listed_count = @nodes.size

    @stats = FleetStatsService.call(UptimeMonitor.public_listed)

    @last_resolved = Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
    @alert_counts = Alert.active.group(:severity).count
    @recent_alerts = Alert.recent.limit(5)
  end
end
