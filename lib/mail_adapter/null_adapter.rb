class MailAdapter::NullAdapter
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    Rails.logger.debug "MailAdapter::NullAdapter: email delivery skipped (no provider configured)"
  end
end
