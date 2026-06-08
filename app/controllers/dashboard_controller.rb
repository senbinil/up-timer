class DashboardController < ApplicationController
  layout "dashboard"

  before_action :authenticate

  def index
    @page_title = "Dashboard"
  end

  private

  def authenticate
    rodauth.require_account
  end
end
