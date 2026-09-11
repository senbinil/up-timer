class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # In-memory cache to avoid DB hits on every request
  # TTL: 5 minutes
  CACHE_TTL = 5.minutes
  # Sentinel for caching non-existent keys to avoid repeated DB hits.
  # Uses a distinct string unlikely to collide with real setting values.
  CACHE_MISS = "__SiteSetting::CACHE_MISS__"

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
    # Creates or updates the setting and busts the cache
    def set(key, value)
      key = key.to_s
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s
      setting.save!
      bust_cache(key)
      setting.value
    end

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
