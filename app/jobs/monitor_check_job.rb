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
      checked_at: Time.current,
      ssl_valid: result.ssl_valid,
      ssl_expires_at: result.ssl_expires_at,
      ssl_issuer: result.ssl_issuer,
      ssl_subject: result.ssl_subject
    )

    if status == "down" && monitor.incidents.where(resolved_at: nil).none?
      monitor.incidents.create!(started_at: Time.current)
      create_trigger_alerts(monitor)
    elsif status == "up"
      monitor.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)
    end
  end

  private

  def create_trigger_alerts(monitor)
    AlertTrigger.active.each do |trigger|
      Alert.create!(
        monitor_id: monitor.id,
        severity: trigger.severity,
        message: "#{trigger.name}: #{monitor.name} is down — #{monitor.url}"
      )
    end
  end
end
