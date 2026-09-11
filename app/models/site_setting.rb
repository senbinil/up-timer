class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  CACHE_TTL = 30.seconds

  # Sentinel for caching non-existent keys. Custom class so it can be
  # marshaled across cache stores without colliding with real values.
  class CacheMiss
    def ==(other)
      other.is_a?(CacheMiss)
    end

    def _dump(_level)
      ""
    end

    def self._load(_str)
      new
    end
  end
  CACHE_MISS = CacheMiss.new.freeze

  class << self
    # Get a setting value by key
    # Returns the cached value if available, otherwise fetches from DB
    # Caches misses to avoid repeated queries for non-existent keys
    def get(key, default: nil)
      key = key.to_s
      cache_key = "site_setting:#{key}"
      cached = Rails.cache.read(cache_key)

      if cached == CACHE_MISS
        default
      elsif cached.nil?
        setting = find_by(key: key)
        if setting
          Rails.cache.write(cache_key, setting.value, expires_in: CACHE_TTL)
          setting.value
        else
          Rails.cache.write(cache_key, CACHE_MISS, expires_in: CACHE_TTL)
          default
        end
      else
        cached
      end
    end

    # Set a setting value by key
    # Creates or updates the setting and busts the cache.
    # Uses upsert to avoid race conditions on the unique key index.
    def set(key, value)
      key = key.to_s
      upsert({ key: key, value: value.to_s }, unique_by: :key)
      bust_cache(key)
      value.to_s
    end

    # Sentinel caches non-existent keys for the TTL window. Currently only
    # one setting exists (registration_enabled); if new settings are added
    # that aren't seeded in every environment, ensure their defaults are
    # handled in their accessor methods rather than relying on this sentinel.

    # Convenience method for boolean settings
    def enabled?(key)
      get(key, default: "false") == "true"
    end

    # Check if registration is enabled (default: true)
    def registration_enabled?
      get(:registration_enabled, default: "true") == "true"
    end

    private

    def bust_cache(key)
      Rails.cache.delete("site_setting:#{key}")
    end
  end
end
