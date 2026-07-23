FactoryBot.define do
  factory :webhook_endpoint do
    url { "https://hooks.example-#{rand(9999)}.com/events" }
    token { SecureRandom.hex(32) }
    token_prefix { token.first(8) }
    active { true }
  end
end
