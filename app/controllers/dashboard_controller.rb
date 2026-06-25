class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
    @nodes = UptimeMonitor.ranked
    @services = @nodes.top(current_dashboard_limit)
    @alerts = Alert.recent.limit(5)
    @alert_counts = Alert.active.group(:severity).count
    @heatmap = Alert.heatmap
    @stats = fleet_stats
  end

  private

  def current_dashboard_limit
    account = Account.find_by(id: rodauth.session_value)
    account&.preference&.dashboard_limit || 3
  end
  helper_method :current_dashboard_limit

  helper_method :chart_data_for, :fleet_stats

  def fleet_stats
    active_ids = UptimeMonitor.active.pluck(:id)
    stats = UptimeMonitor.fleet_stats
    all_checks = MonitorCheck.where(monitor_id: active_ids)
    total_checks = all_checks.count
    up_checks = all_checks.where(status: "up").count

    stats.merge(
      uptime: total_checks > 0 ? (up_checks.to_f / total_checks * 100).round(2) : 100,
      error_rate: total_checks > 0 ? ((total_checks - up_checks).to_f / total_checks * 100).round(2) : 0,
      paused_count: UptimeMonitor.paused.count
    )
  end

  def chart_data_for(node)
    node.monitor_checks.order(checked_at: :desc).limit(24).reverse.map { |c|
      [ c.checked_at.strftime("%H:%M"), c.response_time ]
    }.to_h
  end
end
