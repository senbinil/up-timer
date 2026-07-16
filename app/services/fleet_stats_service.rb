class FleetStatsService
  def self.call(scope = nil)
    new(scope).call
  end

  def initialize(scope = nil)
    @scope = scope || UptimeMonitor.all
  end

  def call
    total = @scope.count
    up_count = @scope.where(status: "up").count
    down_count = total - up_count

    # Uptime/error rate computed from monitor_checks of active (non-paused) monitors
    active_ids = @scope.active.pluck(:id)
    all_checks = MonitorCheck.where(monitor_id: active_ids)
    total_checks = all_checks.count
    up_checks = all_checks.where(status: "up").count

    {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
      total: total,
      uptime: total_checks > 0 ? (up_checks.to_f / total_checks * 100).round(2) : 100,
      error_rate: total_checks > 0 ? ((total_checks - up_checks).to_f / total_checks * 100).round(2) : 0,
      paused_count: @scope.paused.count
    }
  end
end
