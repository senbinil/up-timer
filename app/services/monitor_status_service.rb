class MonitorStatusService
  def self.call(monitor)
    new(monitor).call
  end

  def initialize(monitor)
    @monitor = monitor
  end

  def call
    latest = @monitor.monitor_checks.order(checked_at: :desc).pick(:status)
    return unless latest

    latest == "down" ? handle_down : handle_up
  end

  private

  # Records the outage on the first failure and flips status immediately, but
  # only alerts once the failure is sustained past down_threshold.
  def handle_down
    incident = @monitor.incidents.where(resolved_at: nil).first
    incident ||= @monitor.incidents.create!(started_at: latest_checked_at)

    @monitor.update!(status: "down") unless @monitor.down?

    create_alert(incident) if incident.alert_id.nil? && threshold_met_for_down?
  end

  # Closes the outage on the first success. Recovery is only announced when the
  # incident actually alerted, so silent blips never email recipients.
  def handle_up
    incidents = @monitor.incidents.where(resolved_at: nil).to_a
    resolved_at = latest_checked_at

    @monitor.update!(status: "up") unless @monitor.up?
    return if incidents.empty?

    incidents.each { |incident| incident.update!(resolved_at: resolved_at) }
    resolve_alerts(incidents, resolved_at)

    notify_recovery if incidents.any? { |incident| incident.alert_id.present? }
  end

  def threshold_met_for_down?
    recent = @monitor.monitor_checks
                     .order(checked_at: :desc)
                     .limit(@monitor.down_threshold)
                     .pluck(:status)

    recent.size >= @monitor.down_threshold && recent.all? { |status| status == "down" }
  end

  def latest_checked_at
    @monitor.monitor_checks.order(checked_at: :desc).pick(:checked_at)
  end

  def create_alert(incident)
    trigger = AlertTrigger.find_by(name: "Node Offline")
    return unless trigger

    alert = Alert.create!(
      monitor_id: @monitor.id,
      alert_trigger_id: trigger.id,
      severity: trigger.severity,
      message: "#{trigger.name}: #{@monitor.name} is down — #{@monitor.url}"
    )

    incident.update!(alert_id: alert.id)
  end

  # Resolves exactly the alerts raised by the incidents being closed, so
  # unrelated alerts on the same monitor (e.g. manual ones) are left open.
  def resolve_alerts(incidents, resolved_at)
    alert_ids = incidents.filter_map(&:alert_id)
    return if alert_ids.empty?

    Alert.where(id: alert_ids, resolved: false)
         .update_all(resolved: true, resolved_at: resolved_at)
  end

  def notify_recovery
    return unless MailAdapter.configured?

    Recipient.active.pluck(:email).each do |email|
      AlertMailer.alert_recovered(email, @monitor.id).deliver_now
    end
  end
end
