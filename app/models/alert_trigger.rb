class AlertTrigger < ApplicationRecord
  validates :name, presence: true
  validates :severity, inclusion: { in: %w[critical warning info maintenance] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
