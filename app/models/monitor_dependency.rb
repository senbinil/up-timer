class MonitorDependency < ApplicationRecord
  belongs_to :monitor, class_name: "UptimeMonitor" # the dependent
  belongs_to :dependency, class_name: "UptimeMonitor" # the parent
end
