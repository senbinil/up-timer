class UptimeMonitor < ApplicationRecord
  self.table_name = "monitors"

  has_many :monitor_checks, dependent: :destroy, foreign_key: :monitor_id
  has_many :incidents, dependent: :destroy, foreign_key: :monitor_id
  has_many :alerts, dependent: :destroy, foreign_key: :monitor_id

  after_create_commit :enqueue_first_check
  after_create_commit :enqueue_geo_location, unless: :location_set?
  after_update_commit :enqueue_geo_location, if: :saved_change_to_url?
  before_validation :combine_check_interval_parts, if: :check_interval_parts_changed?

  validates :request_type, inclusion: { in: MonitorCheckService::SUPPORTED_METHODS }
  validates :expected_status, numericality: { only_integer: true, greater_than: 0, less_than: 600 }, allow_nil: true
  validates :request_body, length: { maximum: 10_000 }, allow_blank: true
  validates :down_threshold, numericality: { only_integer: true, in: 1..10 }
  validates :check_interval, numericality: { only_integer: true, greater_than_or_equal_to: 30 }
  validate :check_interval_parsed_successfully

  scope :ranked, -> { order(position: :desc, created_at: :desc) }
  scope :top, ->(n = 3) { ranked.limit(n) }
  scope :active, -> { where(paused: false) }
  scope :paused, -> { where(paused: true) }
  scope :public_listed, -> { where(public_listed: true) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }

  def self.fleet_stats
    total = count
    up_count = where(status: "up").count
    down_count = total - up_count

    {
      status: down_count == 0 ? "operational" : (up_count > 0 ? "degraded" : "down"),
      up_count: up_count,
      down_count: down_count,
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

  def public_uptime
    checks = monitor_checks.where(checked_at: 24.hours.ago..).order(checked_at: :desc)
    total = checks.count
    return { uptime: nil, response_time: nil, recent_checks: [], last_checked_at: nil } if total.zero?

    recent = checks.limit(10).to_a
    up_count = checks.where(status: "up").count

    {
      uptime: (up_count.to_f / total * 100).round(1),
      response_time: recent.first&.response_time,
      last_checked_at: recent.first&.checked_at,
      recent_checks: recent.reverse.map { |c|
        [ c.checked_at.strftime("%I:%M %p"), c.response_time ]
      }.to_h
    }
  end

  def status_heatmap(count: 24)
    monitor_checks
      .order(checked_at: :desc)
      .limit(count)
      .pluck(:status, :checked_at)
      .map { |status, checked_at| { status: status, checked_at: checked_at } }
  end

  def last_check_at
    monitor_checks.order(checked_at: :desc).pick(:checked_at)
  end

  def down?
    status == "down"
  end

  def up?
    status == "up"
  end

  def paused?
    paused
  end

  def dependency_affected?
    false
  end

  def check_interval_display
    DurationParser.format(check_interval)
  end

  def check_interval_hours
    instance_variable_defined?(:@check_interval_hours) ? @check_interval_hours : (check_interval ? check_interval / 3600 : 0)
  end

  def check_interval_minutes
    instance_variable_defined?(:@check_interval_minutes) ? @check_interval_minutes : (check_interval ? (check_interval % 3600) / 60 : 0)
  end

  def check_interval_seconds
    instance_variable_defined?(:@check_interval_seconds) ? @check_interval_seconds : (check_interval ? check_interval % 60 : 0)
  end

  def check_interval_hours=(value)
    @check_interval_parts_changed = true
    @check_interval_hours = value.to_i
  end

  def check_interval_minutes=(value)
    @check_interval_parts_changed = true
    @check_interval_minutes = value.to_i
  end

  def check_interval_seconds=(value)
    @check_interval_parts_changed = true
    @check_interval_seconds = value.to_i
  end

  def check_interval=(value)
    if value.is_a?(String) && !value.match?(/\A\d+\z/)
      parsed = DurationParser.parse(value)
      if parsed
        super(parsed)
      else
        @check_interval_parse_error = "is not a valid interval. Use formats like 30s, 5m, 2h, or a number of seconds"
        super(nil)
      end
    else
      super(value)
    end
  end

  def location_set?
    latitude.present? && longitude.present?
  end

  def last_pause_log
    ActionLog.for_record(self.class.name, id).where(action: "paused").recent.first
  end

  private

  def check_interval_parts_changed?
    @check_interval_parts_changed
  end

  def combine_check_interval_parts
    self.check_interval = (@check_interval_hours.to_i * 3600) +
                          (@check_interval_minutes.to_i * 60) +
                          (@check_interval_seconds.to_i)
  end

  def check_interval_parsed_successfully
    if @check_interval_parse_error
      errors.add(:check_interval, @check_interval_parse_error)
      @check_interval_parse_error = nil
    end
  end

  def enqueue_first_check
    MonitorCheckJob.perform_later(id)
  end

  def enqueue_geo_location
    GeoLocationJob.perform_later(id)
  end
end
