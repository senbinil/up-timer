FactoryBot.define do
  factory :alert do
    message { "Test alert message" }
    severity { "info" }
    resolved { false }
    monitor { association :uptime_monitor }
    account { association :account }
  end
end
