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

    threshold = monitor.down_threshold
    recent = monitor.monitor_checks
                    .order(checked_at: :desc)
                    .limit(threshold)
                    .pluck(:status)

    if recent.all?("down") && recent.size >= threshold
      monitor.update!(status: "down") unless monitor.down?
      if monitor.incidents.where(resolved_at: nil).none?
        monitor.incidents.create!(started_at: Time.current)
        create_trigger_alerts(monitor)
      end
    elsif recent.all?("up") && recent.size >= threshold
      if monitor.down?
        monitor.update!(status: "up")
        monitor.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)
        create_recovery_alerts(monitor)
      end
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

  def create_recovery_alerts(monitor)
    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_recovered(email, monitor.id).deliver_later
    end
  end
end
