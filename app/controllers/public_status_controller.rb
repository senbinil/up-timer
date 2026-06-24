class PublicStatusController < ApplicationController
  layout "public_status"

  def show
    @account = Account.find_by!(status_token: params[:token])
    @nodes = UptimeMonitor.ranked
    @stats = UptimeMonitor.fleet_stats
    @last_resolved = Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
    @recent_alerts = Alert.recent.limit(5)
  end
end
