FactoryBot.define do
  factory :monitor_dependency do
    monitor { association :uptime_monitor }
    dependency { association :uptime_monitor }
  end
end
