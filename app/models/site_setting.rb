class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # In-memory cache to avoid DB hits on every request
  # TTL: 5 minutes
  CACHE_TTL = 5.minutes

  class << self
    # Get a setting value by key
    # Returns the cached value if available, otherwise fetches from DB
    def get(key, default: nil)
      cache_key = "site_setting:#{key}"
      cached = Rails.cache.read(cache_key)

      if cached.nil?
        setting = find_by(key: key)
        if setting
          Rails.cache.write(cache_key, setting.value, expires_in: CACHE_TTL)
          setting.value
        else
          default
        end
      else
        cached
      end
    end

    # Set a setting value by key
    # Creates or updates the setting and busts the cache
    def set(key, value)
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s
      setting.save!
      bust_cache(key)
      setting.value
    end

    # Convenience method for boolean settings
    def enabled?(key)
      get(key, default: "true") == "true"
    end

    # Check if registration is enabled (default: true)
    def registration_enabled?
      enabled?(:registration_enabled)
    end

    private

    def bust_cache(key)
      Rails.cache.delete("site_setting:#{key}")
    end
  end
end
