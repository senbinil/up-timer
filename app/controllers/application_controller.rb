class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_account
    return nil unless rodauth.session_value
    @current_account ||= Account.find_by(id: rodauth.session_value)
  end
  helper_method :current_account

  def require_role!(min_role)
    return unless current_account

    allowed = case min_role
    when :viewer then true
    when :collaborator then current_account.collaborator?
    when :admin then current_account.admin?
    end

    unless allowed
      redirect_to dashboard_path, alert: "You don't have permission to access this page."
    end
  end
end
