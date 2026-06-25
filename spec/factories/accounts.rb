FactoryBot.define do
  factory :account do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    password_hash { RodauthApp.rodauth.allocate.password_hash("password") }
    status { :verified }
    role { "viewer" }
  end
end
