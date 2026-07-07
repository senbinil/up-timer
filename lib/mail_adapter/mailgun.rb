class MailAdapter::Mailgun
  def self.configure!
    if ENV["MAILGUN_API_KEY"].present? && ENV["MAILGUN_DOMAIN"].present?
      api_key = ENV["MAILGUN_API_KEY"]
      domain  = ENV["MAILGUN_DOMAIN"]
      api_host = ENV["MAILGUN_API_HOST"]

      Mailgun.configure do |config|
        config.api_key = api_key
        config.api_host = api_host if api_host.present?
      end

      ActionMailer::Base.add_delivery_method :mailgun, MailgunDelivery, api_key: api_key, domain: domain

      if Rails.application.initialized?
        ActionMailer::Base.delivery_method = :mailgun
      else
        Rails.application.config.after_initialize do
          ActionMailer::Base.delivery_method = :mailgun
        end
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

  class MailgunDelivery
    attr_accessor :settings

    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      client = ::Mailgun::Client.new(settings[:api_key], settings[:api_host] || "api.mailgun.net")
      client.send_message(settings[:domain], build_message(mail))
    end

    private

    def build_message(mail)
      {
        from:    mail[:from].to_s,
        to:      mail[:to].to_s,
        subject: mail.subject,
        html:    mail.html_part&.body&.to_s,
        text:    mail.text_part&.body&.to_s
      }.compact
    end
  end
end
