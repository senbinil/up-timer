module MailAdapter
  def self.configured?
    Rails.application.config.respond_to?(:email_configured) &&
      Rails.application.config.email_configured
  end
end
