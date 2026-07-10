class DashboardBroadcastService
  def self.call(updated_nodes:, new_alerts: [])
    new(updated_nodes, new_alerts).call
  end

  def initialize(updated_nodes, new_alerts = [])
    @updated_nodes = Array(updated_nodes)
    @new_alerts = Array(new_alerts)
  end

  def call
    html = ApplicationController.render(
      template: "dashboard/broadcast",
      layout: false,
      assigns: {
        updated_nodes: @updated_nodes,
        new_alerts: @new_alerts,
        stats: stats,
        alert_counts: alert_counts
      }
    )

    Turbo::StreamsChannel.broadcast_stream_to("dashboard", content: html)
  end

  private

  def stats
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

  def alert_counts
    Alert.active.group(:severity).count
  end
end
