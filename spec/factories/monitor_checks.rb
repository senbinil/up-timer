FactoryBot.define do
  factory :monitor_check do
    monitor { association :uptime_monitor }
    status { "up" }
    status_code { 200 }
    response_time { rand(50..500).to_f }
    checked_at { Time.current }
  end
end
