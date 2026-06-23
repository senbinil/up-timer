class MonitorCheck < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor"

  def ssl_days_remaining
    return nil unless ssl_expires_at
    ((ssl_expires_at - Time.current) / 1.day).to_i
  end
end
