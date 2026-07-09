class Alert < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor", optional: true
  belongs_to :account, optional: true
  belongs_to :resolved_by, class_name: "Account", optional: true
  belongs_to :alert_trigger, optional: true

  validates :severity, inclusion: { in: %w[critical warning info] }
  validates :message, presence: true

  after_create_commit :notify_recipients, if: :persisted?
  before_destroy :log_destroy

  scope :active, -> { where(resolved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }

  def self.heatmap(days = 14)
    start_date = days.days.ago.to_date
    # Single query: fetch all relevant rows, group in Ruby
    rows = where(created_at: start_date.beginning_of_day..)
      .pluck(:created_at, :severity)

    grouped = rows.group_by { |time, _| time.in_time_zone.to_date }

    days.downto(0).map do |days_ago|
      date = days_ago.days.ago.to_date
      day_alerts = grouped[date] || []
      {
        date: date,
        count: day_alerts.size,
        critical: day_alerts.count { |_, s| s == "critical" },
        warning: day_alerts.count { |_, s| s == "warning" },
        info: day_alerts.count { |_, s| s == "info" }
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
