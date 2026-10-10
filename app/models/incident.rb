class Incident < ApplicationRecord
  SIGNIFICANT_MIN_DURATION = 1.minute

  belongs_to :monitor, class_name: "UptimeMonitor"
  belongs_to :alert, optional: true

  scope :resolved, -> { where.not(resolved_at: nil) }

  def duration
    return nil unless resolved_at

    resolved_at - started_at
  end

  # An incident is worth surfacing if it alerted, is still open, or lasted long
  # enough to be a real outage rather than a single-check blip.
  def significant?
    alert_id.present? || resolved_at.nil? || duration >= SIGNIFICANT_MIN_DURATION
  end

  def self.last_significant_resolved_at
    resolved.order(resolved_at: :desc).find(&:significant?)&.resolved_at
  end
end
