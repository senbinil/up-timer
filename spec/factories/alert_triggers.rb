FactoryBot.define do
  factory :alert_trigger do
    sequence(:name) { |n| "Trigger #{n}" }
    severity { "warning" }
    description { "Triggers when something happens" }
    email_notify { false }
  end
end
