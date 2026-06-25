class RodauthController < ApplicationController
  # Used by Rodauth for rendering views, CSRF protection, running any
  # registered action callbacks and rescue handlers, instrumentation etc.

  # Controller callbacks and rescue handlers will run around Rodauth endpoints.
  # before_action :verify_captcha, only: :login, if: -> { request.post? }
  # rescue_from("SomeError") { |exception| ... }

  # Layout can be changed for all Rodauth pages or only certain pages.
  # layout "authentication"
  # layout -> do
  #   case rodauth.current_route
  #   when :login, :create_account, :verify_account, :verify_account_resend,
  #        :reset_password, :reset_password_request
  #     "authentication"
  #   else
  #     "application"
  #   end
  # end

  # Redirect authenticated users away from the login page when accessing
  # the root path (/). The Rodauth middleware handles this for /login, but
  # / goes through the Rails router (root to: "rodauth#login") and bypasses
  # the already_logged_in check defined in the Rodauth config.
  before_action :redirect_authenticated_user, only: :login

  private

  def redirect_authenticated_user
    redirect_to dashboard_path if rodauth.logged_in?
  end
end
