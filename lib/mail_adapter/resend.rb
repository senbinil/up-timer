class MailAdapter::Resend
  def self.configure!
    if ENV["RESEND_API_KEY"].present?
      Resend.api_key = ENV["RESEND_API_KEY"]
      Rails.application.config.action_mailer.delivery_method = :resend

      # Rails' ActionMailer railtie resets delivery_method during boot,
      # so apply it again after all initializers finish.
      Rails.application.config.after_initialize do
        ActionMailer::Base.delivery_method = :resend
      end

      Rails.logger.info "MailAdapter: using Resend for email delivery"
      true
    else
      Rails.logger.warn "MailAdapter: RESEND_API_KEY missing — email delivery disabled"
      false
    end
  end
end
