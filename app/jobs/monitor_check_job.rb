class MonitorCheckJob < ApplicationJob
  queue_as :default

  def perform(monitor_id)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor

    result = MonitorCheckService.call(monitor)
    status = result.up ? "up" : "down"

    monitor.update!(status: status)
    monitor.monitor_checks.create!(
      status: status,
      response_time: result.duration,
      status_code: result.code,
      checked_at: Time.current
    )

    if status == "down" && monitor.incidents.where(resolved_at: nil).none?
      monitor.incidents.create!(started_at: Time.current)
    elsif status == "up"
      monitor.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)
    end
  end
end
