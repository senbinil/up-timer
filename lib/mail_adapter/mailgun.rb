class MailAdapter::Mailgun
  def self.configure!
    if ENV["MAILGUN_API_KEY"].present? && ENV["MAILGUN_DOMAIN"].present?
      settings = {
        api_key:  ENV["MAILGUN_API_KEY"],
        domain:   ENV["MAILGUN_DOMAIN"],
        api_host: ENV["MAILGUN_API_HOST"].presence || "api.mailgun.net"
      }

      if Rails.application.initialized?
        ActionMailer::Base.mailgun_settings = settings
        ActionMailer::Base.delivery_method = :mailgun
      else
        Rails.application.config.after_initialize do
          ActionMailer::Base.mailgun_settings = settings
          ActionMailer::Base.delivery_method = :mailgun
        end
      end

      Rails.logger.info "MailAdapter: using Mailgun (#{settings[:api_host]}) for email delivery"
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
