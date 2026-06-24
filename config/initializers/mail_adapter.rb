require "mail_adapter"
require "mail_adapter/null_adapter"
require "mail_adapter/resend"
require "mail_adapter/mailgun"

ActionMailer::Base.add_delivery_method :null_mail, MailAdapter::NullAdapter

# Dev/test use letter_opener / :test delivery — email is functional by default.
# Production requires an explicit provider; falls back to null adapter otherwise.
configured = !Rails.env.production?

if Rails.env.production?
  provider = ENV["MAIL_PROVIDER"]&.downcase

  configured = case provider
  when "resend"  then MailAdapter::Resend.configure!
  when "mailgun" then MailAdapter::Mailgun.configure!
  else
                 if provider.present?
                   Rails.logger.warn "MailAdapter: unknown MAIL_PROVIDER '#{provider}' — email delivery disabled"
                 else
                   Rails.logger.info "MailAdapter: MAIL_PROVIDER not set — email delivery disabled"
                 end
                 false
  end

  unless configured
    Rails.application.config.action_mailer.delivery_method = :null_mail
  end
end

Rails.application.config.email_configured = configured
