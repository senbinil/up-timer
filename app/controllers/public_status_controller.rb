class PublicStatusController < ApplicationController
  layout "public_status"

  def show
    @account = Account.find_by!(status_token: params[:token])
    @nodes = UptimeMonitor.ranked.includes(:monitor_checks)
    @stats = UptimeMonitor.fleet_stats
    @last_resolved = Incident.where(resolved_at: ..Time.current).maximum(:resolved_at)
    @alert_counts = Alert.active.group(:severity).count
    @recent_alerts = Alert.recent.limit(5)
  end
end
