class UptimeMonitor < ApplicationRecord
  self.table_name = "monitors"

  has_many :monitor_checks, dependent: :destroy, foreign_key: :monitor_id
  has_many :incidents, dependent: :destroy, foreign_key: :monitor_id

  scope :ranked, -> { order(position: :desc, created_at: :desc) }
  scope :top, ->(n = 3) { ranked.limit(n) }
end
