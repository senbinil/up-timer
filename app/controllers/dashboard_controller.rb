class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
    @nodes = UptimeMonitor.all.order(created_at: :desc)
    @services = @nodes.first(3)
    @alerts = Alert.recent.limit(5)
  end

  private

  helper_method :chart_data_for

  def chart_data_for(node)
    node.monitor_checks.order(checked_at: :desc).limit(24).reverse.map { |c|
      [ c.checked_at.strftime("%H:%M"), c.response_time ]
    }.to_h
  end

  def authenticate
    rodauth.require_account
  end
end
