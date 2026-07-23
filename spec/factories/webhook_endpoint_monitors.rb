FactoryBot.define do
  factory :webhook_endpoint_monitor do
    webhook_endpoint
    monitor factory: :uptime_monitor
    events { "check_result,status_change" }
  end
end
