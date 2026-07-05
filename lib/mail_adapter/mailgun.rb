class MailAdapter::Mailgun
  def self.configure!
    if ENV["MAILGUN_API_KEY"].present? && ENV["MAILGUN_DOMAIN"].present?
      Mailgun.configure do |config|
        config.api_key = ENV["MAILGUN_API_KEY"]
      end

      Rails.application.config.action_mailer.delivery_method = :mailgun
      Rails.application.config.action_mailer.mailgun_settings = {
        api_key: ENV["MAILGUN_API_KEY"],
        domain: ENV["MAILGUN_DOMAIN"]
      }

      # Rails' ActionMailer railtie resets delivery_method during boot,
      # so apply it again after all initializers finish.
      Rails.application.config.after_initialize do
        ActionMailer::Base.delivery_method = :mailgun
      end

      Rails.logger.info "MailAdapter: using Mailgun for email delivery"
      true
    else
      missing = []
      missing << "MAILGUN_API_KEY" if ENV["MAILGUN_API_KEY"].blank?
      missing << "MAILGUN_DOMAIN" if ENV["MAILGUN_DOMAIN"].blank?
      Rails.logger.warn "MailAdapter: #{missing.join(", ")} missing — email delivery disabled"
      false
    end
  end
end
