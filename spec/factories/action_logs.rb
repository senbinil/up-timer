FactoryBot.define do
  factory :action_log do
    action { "created" }
    record_type { "UptimeMonitor" }
    sequence(:record_id)
    account { association :account }
    metadata { {} }
  end
end
