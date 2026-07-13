class DbAdapter::Sqlite
  def self.configure!
    Rails.logger.info "DbAdapter: using SQLite"

    # database.yml already configures all 4 databases (primary, queue, cache, cable)
    # for SQLite. production.rb pins solid_queue to :queue.
    # cable.yml pins solid_cable to :cable.
    # cache.yml pins solid_cache to cache.
    # No changes needed — this is the default behavior.
  end
end
