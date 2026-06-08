class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
    @nodes = UptimeMonitor.all.order(created_at: :desc)
    @services = @nodes.first(3)
    @alerts = Alert.recent.limit(5)
    @stats = fleet_stats
  end

  private

  helper_method :chart_data_for, :fleet_stats

  def fleet_stats
    total = @nodes.size
    up_count = @nodes.where(status: "up").count
    down_count = total - up_count

    all_checks = MonitorCheck.where(monitor_id: @nodes.pluck(:id))
    total_checks = all_checks.count
    up_checks = all_checks.where(status: "up").count

    {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
      total: total,
      uptime: total_checks > 0 ? (up_checks.to_f / total_checks * 100).round(2) : 100,
      error_rate: total_checks > 0 ? ((total_checks - up_checks).to_f / total_checks * 100).round(2) : 0
    }
  end

  def chart_data_for(node)
    node.monitor_checks.order(checked_at: :desc).limit(24).reverse.map { |c|
      [ c.checked_at.strftime("%H:%M"), c.response_time ]
    }.to_h
  end

  def authenticate
    rodauth.require_account
  end
end
