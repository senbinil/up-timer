require "sequel/core"

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    # When email is not configured, disable features that require email delivery.
    if MailAdapter.configured?
      enable :create_account, :verify_account, :verify_account_grace_period,
        :login, :logout, :remember,
        :reset_password, :change_password, :change_login, :verify_login_change,
        :close_account
    else
      enable :create_account,
        :login, :logout, :remember,
        :close_account
    end

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.sqlite(extensions: :activerecord_connection, keep_reference: false)
    # Avoid DB query that checks accounts table schema at boot time.
    convert_token_id_to_integer? { Account.columns_hash["id"].type == :integer }

    # Change prefix of table and foreign key column names from default "account"
    # accounts_table :users
    # verify_account_table :user_verification_keys
    # verify_login_change_table :user_login_change_keys
    # reset_password_table :user_password_reset_keys
    # remember_table :user_remember_keys

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "1ac1df15c643f2865561325f1b17aa7344896716f2d3e1d789b2eb18791872e6868654ac707a08a7e1e7a3e76c0eef9f03b4023a978949d0c1f2925af79f1196"

    # Use path prefix for all routes.
    # prefix "/auth"

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { RodauthController }

    # Make built-in page titles accessible in your views via an instance variable.
    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false if MailAdapter.configured?

    # Change some default param keys.
    login_param "email"
    login_confirm_param "email-confirm"
    password_confirm_param "confirm_password"

    # Disable login confirmation (not present in the form) regardless of
    # whether verify_account is loaded. The verify_account feature already
    # disables this (require_login_confirmation? false), but when email is
    # not configured, verify_account is not loaded and the default is true.
    require_login_confirmation? false

    # Redirect back to originally requested location after authentication.
    # login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    already_logged_in { redirect "/dashboard" }

    # NOTE: When email is not configured, password reset still generates a
    # valid token but no email is sent. The user sees a success message with
    # no delivery. This is by design — the feature remains functional when
    # email is later configured.
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    if MailAdapter.configured?
      create_verify_account_email do
        RodauthMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
      end
    end
    if MailAdapter.configured?
      create_reset_password_email do
        RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
      end
    end
    if MailAdapter.configured?
      create_verify_login_change_email do |_login|
        RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
      end
    end

    # ==> Flash
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    if MailAdapter.configured?
      # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    else
      create_account_notice_flash "Your account has been created and is ready to use."
    end
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8
    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end

    # ==> Remember Feature
    # Remember all logged in users.
    after_login { remember_login }

    # Or only remember users that have ticked a "Remember Me" checkbox on login.
    # after_login { remember_login if param_or_nil("remember") }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # ==> Hooks
    # Validate custom fields in the create account form.
    before_create_account do
      throw_error_status(422, "name", "must be present") if param("name").blank?
      throw_error_status(422, "compliance", "must be accepted") unless param("compliance") == "1"
    end

    # Perform additional actions after the account is created.
    after_create_account do
      account = Account.find(account_id)
      role = account.email.in?(ADMIN_EMAILS) ? "admin" : "viewer"
      attrs = { name: param("name"), role: role }
      # Auto-verify when email delivery is not configured.
      attrs[:status] = Account.statuses[:verified] unless MailAdapter.configured?
      account.update!(attrs)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Account creation error: #{e.message}"
      raise
    end

    # Do additional cleanup after the account is closed.
    # after_close_account do
    #   Profile.find_by!(account_id: account_id).destroy
    # end

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect after successful login.
    login_redirect "/dashboard"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect } if MailAdapter.configured?

    # Redirect to login page after password reset.
    reset_password_redirect { login_path } if MailAdapter.configured?

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
    # remember_deadline_interval Hash[days: 30]
  end
end
