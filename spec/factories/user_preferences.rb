FactoryBot.define do
  factory :user_preference do
    account { association :account }
    dashboard_limit { 3 }
  end
end
