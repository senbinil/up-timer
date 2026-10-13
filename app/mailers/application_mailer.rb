class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM") }
  layout "mailer"
end
