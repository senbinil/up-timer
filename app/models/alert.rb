class Alert < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor", optional: true

  validates :severity, inclusion: { in: %w[critical warning info] }
  validates :message, presence: true

  after_create_commit :notify_recipients, if: :persisted?

  scope :active, -> { where(resolved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }

  private

  def notify_recipients
    AlertNotificationJob.perform_later(id)
  end
end
