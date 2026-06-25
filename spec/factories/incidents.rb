FactoryBot.define do
  factory :incident do
    monitor { association :uptime_monitor }
    started_at { Time.current }
  end
end
