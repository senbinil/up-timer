class DbAdapter::Postgres
  def self.configure!
    Rails.logger.info "DbAdapter: using PostgreSQL"

    # Override Solid* configs to use the primary database (connected via DATABASE_URL).
    # By default they're pinned to separate :queue and :cache databases in database.yml.
    # We reconfigure them after initialization so all use the single PostgreSQL database.
    Rails.application.config.after_initialize do
      if Rails.application.config.respond_to?(:solid_queue)
        Rails.application.config.solid_queue.connects_to = { database: { writing: :primary } }
        Rails.logger.info "DbAdapter: routed Solid Queue to primary database"
      end

      if Rails.application.config.respond_to?(:solid_cache)
        Rails.application.config.solid_cache.connects_to = { database: { writing: :primary } }
        Rails.logger.info "DbAdapter: routed Solid Cache to primary database"
      end
    end
  end
end
