require "flipper/adapters/active_record"

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::ActiveRecord.new }
end

Rails.application.config.after_initialize do
  if MailAdapter.configured?
    Flipper.enable(:email_notifications) unless Flipper.enabled?(:email_notifications)
  end
rescue ActiveRecord::StatementInvalid
  # DB not ready yet (e.g. test environment)
end
