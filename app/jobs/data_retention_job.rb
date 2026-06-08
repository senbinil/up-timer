class DataRetentionJob < ApplicationJob
  queue_as :default

  CHECK_RETENTION_DAYS = 30
  INCIDENT_RETENTION_DAYS = 90

  def perform
    # Archive old monitor checks
    cutoff = CHECK_RETENTION_DAYS.days.ago
    deleted = MonitorCheck.where("checked_at < ?", cutoff).delete_all
    Rails.logger.info "DataRetention: deleted #{deleted} monitor_checks older than #{CHECK_RETENTION_DAYS} days"

    # Archive old resolved incidents
    incident_cutoff = INCIDENT_RETENTION_DAYS.days.ago
    resolved_deleted = Incident.where(resolved_at: ..incident_cutoff).delete_all
    Rails.logger.info "DataRetention: deleted #{resolved_deleted} resolved incidents older than #{INCIDENT_RETENTION_DAYS} days"
  end
end
