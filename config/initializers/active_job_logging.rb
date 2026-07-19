# Silence chatty recurring broadcast jobs from cluttering production logs.
# ActiveJob logs every enqueue/perform at info level — DashboardBroadcastJob runs every 2s.
Rails.application.config.after_initialize do
  ActiveJob::Base.logger.level = Logger::WARN if Rails.env.production?
end
