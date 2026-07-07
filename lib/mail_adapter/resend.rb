class MailAdapter::Resend
  def self.configure!
    if ENV["RESEND_API_KEY"].present?
      Resend.api_key = ENV["RESEND_API_KEY"]

      if Rails.application.initialized?
        ActionMailer::Base.delivery_method = :resend
      else
        Rails.application.config.after_initialize do
          ActionMailer::Base.delivery_method = :resend
        end
      end

      Rails.logger.info "MailAdapter: using Resend for email delivery"
      true
    else
      Rails.logger.warn "MailAdapter: RESEND_API_KEY missing — email delivery disabled"
      false
    end
  end
end
