class AlertTrigger < ApplicationRecord
  validates :name, presence: true
  validates :severity, inclusion: { in: %w[critical warning info maintenance] }

  scope :ordered, -> { order(:name) }
  scope :email_notify, -> { where(email_notify: true) }

  def last_action_log
    ActionLog.for_record(self.class.name, id).recent.first
  end
end
