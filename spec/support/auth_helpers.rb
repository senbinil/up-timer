module AuthHelpers
  def sign_in(account = nil)
    account ||= create(:account, role: "admin")
    post "/login", params: { email: account.email, password: "password" }
    account
  end

  def sign_in_as(role)
    account = create(:account, role: role)
    sign_in(account)
    account
  end

  def sign_in_admin
    sign_in_as("admin")
  end

  def sign_in_collaborator
    sign_in_as("collaborator")
  end

  def sign_in_viewer
    sign_in_as("viewer")
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
