FactoryBot.define do
  factory :recipient do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    active { true }
  end
end
