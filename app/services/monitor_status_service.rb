class MonitorStatusService
  def self.call(monitor)
    new(monitor).call
  end

  def initialize(monitor)
    @monitor = monitor
  end

  def call
    return unless threshold_met?

    if target_status == "down"
      transition_to_down
    else
      transition_to_up
    end
  end

  private

  def threshold_met?
    recent = @monitor.monitor_checks
                     .order(checked_at: :desc)
                     .limit(@monitor.down_threshold)
                     .pluck(:status)

    recent.size >= @monitor.down_threshold && recent.all?(target_status)
  end

  def target_status
    @target_status ||= @monitor.monitor_checks.pick(:status)
  end

  def transition_to_down
    return if @monitor.down?

    @monitor.update!(status: "down")
    create_incident_and_alerts if @monitor.incidents.where(resolved_at: nil).none?
  end

  def transition_to_up
    return unless @monitor.down?

    @monitor.update!(status: "up")
    @monitor.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)
    notify_recovery
  end

  def create_incident_and_alerts
    @monitor.incidents.create!(started_at: Time.current)
    AlertTrigger.active.each do |trigger|
      Alert.create!(
        monitor_id: @monitor.id,
        severity: trigger.severity,
        message: "#{trigger.name}: #{@monitor.name} is down — #{@monitor.url}"
      )
    end
  end

  def notify_recovery
    return unless MailAdapter.configured?
    return unless Flipper.enabled?(:email_notifications)

    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_recovered(email, @monitor.id).deliver_later
    end
  end
end
