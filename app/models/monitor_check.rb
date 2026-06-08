class MonitorCheck < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor"
end
