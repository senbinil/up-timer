class StatusPageBroadcastService
  def self.call(updated_nodes:, new_alerts: [])
    new(updated_nodes, new_alerts).call
  end

  def initialize(updated_nodes, new_alerts = [])
    @updated_nodes = Array(updated_nodes)
    @new_alerts = Array(new_alerts)
  end

  def call
    public_nodes = @updated_nodes.select(&:public_listed?)
    return if public_nodes.empty? && @new_alerts.empty?

    html = ApplicationController.render(
      template: "home/broadcast",
      layout: false,
      assigns: {
        updated_nodes: public_nodes,
        new_alerts: @new_alerts,
        stats: stats,
        alert_counts: alert_counts,
        last_resolved: last_resolved
      }
    )

    Turbo::StreamsChannel.broadcast_stream_to("public_status", content: html)
  end

  private

  def stats
    FleetStatsService.call(UptimeMonitor.public_listed)
  end

  def alert_counts
    Alert.active.group(:severity).count
  end

  def last_resolved
    Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
  end
end
