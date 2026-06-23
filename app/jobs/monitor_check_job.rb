class MonitorCheckJob < ApplicationJob
  queue_as :default

  def perform(monitor_id)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor

    result = MonitorCheckService.call(monitor)
    status = result.up ? "up" : "down"

    monitor.monitor_checks.create!(
      status: status,
      response_time: result.duration,
      status_code: result.code,
      checked_at: Time.current
    )

    MonitorStatusService.call(monitor)
  end
end
