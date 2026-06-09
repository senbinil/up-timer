class PublicStatusController < ApplicationController
  layout "public_status"

  def show
    @account = Account.find_by!(status_token: params[:token])
    @nodes = UptimeMonitor.ranked
    @stats = fleet_stats
    @last_resolved = Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
    @recent_alerts = Alert.recent.limit(5)
  end

  private

  def fleet_stats
    total = @nodes.size
    up_count = @nodes.where(status: "up").count
    down_count = total - up_count

    {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
      total: total
    }
  end
end
