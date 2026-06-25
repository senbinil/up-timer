FactoryBot.define do
  factory :uptime_monitor do
    sequence(:name) { |n| "Monitor #{n}" }
    url { "https://example-#{rand(9999)}.com" }
    check_interval { 60 }
    timeout { 30 }
    request_type { "GET" }
    status { "unknown" }
    down_threshold { 1 }
    position { 0 }
    tags { [] }
  end
end
