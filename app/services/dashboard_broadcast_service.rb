class DashboardBroadcastService
  def self.call(updated_nodes:, new_alerts: [])
    new(updated_nodes, new_alerts).call
  end

  def initialize(updated_nodes, new_alerts = [])
    @updated_nodes = Array(updated_nodes)
    @new_alerts = Array(new_alerts)
  end

  def call
    Turbo::StreamsChannel.broadcast_stream_to("dashboard", content: broadcast_content)
  end

  private

  def broadcast_content
    streams = []

    @new_alerts.each do |alert|
      streams << render_stream(:prepend, "recent_alerts",
        partial: "alerts/alert_row", locals: { alert: alert })
    end

    @updated_nodes.each do |node|
      streams << render_stream(:replace, ActionView::RecordIdentifier.dom_id(node),
        partial: "nodes/node_card", locals: { node: node })
    end

    streams << render_stream(:replace, "fleet_status",
      partial: "dashboard/fleet_status", locals: {
        stats: stats, alert_counts: alert_counts, nodes: UptimeMonitor.ranked
      })

    streams.join
  end

  def render_stream(action, target, partial:, locals: {})
    target_escaped = target.gsub("'", "\\\\'")
    ApplicationController.render(
      inline: "<%= turbo_stream.#{action}('#{target_escaped}', partial: '#{partial}', locals: { #{locals.keys.map { |k| "#{k}: #{k}" }.join(', ')} }) %>",
      type: :erb,
      locals: locals
    )
  end

  def stats
    FleetStatsService.call
  end

  def alert_counts
    Alert.active.group(:severity).count
  end
end
