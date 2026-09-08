class DashboardController < ApplicationController
  include LoadableFleetStats

  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
    @nodes = UptimeMonitor.ranked
    @services = @nodes.top(current_dashboard_limit)
    @alerts = Alert.recent.limit(5)
    @alert_counts = Alert.active.group(:severity).count
  end

  private

  def current_dashboard_limit
    account = Account.find_by(id: rodauth.session_value)
    account&.preference&.dashboard_limit || 3
  end
  helper_method :current_dashboard_limit
end
