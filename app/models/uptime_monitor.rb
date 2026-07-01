class UptimeMonitor < ApplicationRecord
  self.table_name = "monitors"

  has_many :monitor_checks, dependent: :destroy, foreign_key: :monitor_id
  has_many :incidents, dependent: :destroy, foreign_key: :monitor_id
  has_many :alerts, dependent: :destroy, foreign_key: :monitor_id

  # Dependencies: this monitor depends on others (parents)
  has_many :monitor_dependencies, foreign_key: :monitor_id, dependent: :destroy
  has_many :dependencies, through: :monitor_dependencies, source: :dependency

  # Reverse: other monitors depend on this one (children)
  has_many :dependent_monitor_dependencies, class_name: "MonitorDependency", foreign_key: :dependency_id, dependent: :destroy
  has_many :dependents, through: :dependent_monitor_dependencies, source: :monitor

  after_create_commit :enqueue_first_check

  validates :request_type, inclusion: { in: MonitorCheckService::SUPPORTED_METHODS }
  validates :expected_status, numericality: { only_integer: true, greater_than: 0, less_than: 600 }, allow_nil: true
  validates :request_body, length: { maximum: 10_000 }, allow_blank: true
  validates :down_threshold, numericality: { only_integer: true, in: 1..10 }

  scope :ranked, -> { order(position: :desc, created_at: :desc) }
  scope :top, ->(n = 3) { ranked.limit(n) }
  scope :active, -> { where(paused: false) }
  scope :paused, -> { where(paused: true) }
  scope :dependency_affected, -> { where(dependency_affected: true) }

  def self.fleet_stats
    total = count
    up_count = where(status: "up").count
    down_count = total - up_count
    affected_count = dependency_affected.count

    {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
      affected_count: affected_count,
      total: total
    }
  end

  def self.all_tags
    pluck(:tags).flatten.uniq.sort
  end

  def tag_list
    (tags || []).join(", ")
  end

  def tag_list=(value)
    self.tags = value.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  def down?
    status == "down"
  end

  def up?
    status == "up"
  end

  def dependency_affected?
    dependency_affected
  end

  def paused?
    paused
  end

  def last_pause_log
    ActionLog.for_record(self.class.name, id).where(action: "paused").recent.first
  end

  def available_dependencies
    # Other nodes that are not already dependencies and not self
    UptimeMonitor.where.not(id: [ id ] + dependency_ids + dependent_ids)
  end

  private

  def enqueue_first_check
    MonitorCheckJob.perform_later(id)
  end
end
