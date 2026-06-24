class Alert < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor", optional: true
  belongs_to :account, optional: true
  belongs_to :resolved_by, class_name: "Account", optional: true

  validates :severity, inclusion: { in: %w[critical warning info] }
  validates :message, presence: true

  after_create_commit :notify_recipients, if: :persisted?
  before_destroy :log_destroy

  scope :active, -> { where(resolved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }

  def self.heatmap(days = 14)
    days.downto(0).map do |days_ago|
      date = days_ago.days.ago.to_date
      day_alerts = where(created_at: date.all_day)
      {
        date: date,
        count: day_alerts.count,
        critical: day_alerts.where(severity: "critical").count,
        warning: day_alerts.where(severity: "warning").count,
        info: day_alerts.where(severity: "info").count
      }
    end
  end

  private

  def notify_recipients
    AlertNotificationJob.perform_later(id)
  end

  def log_destroy
    ActionLog.log(
      action: :destroyed,
      record: self,
      metadata: { name: monitor&.name, severity: severity, message: message }
    )
  end
end
