class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true, length: { minimum: 1 }

  CACHE_TTL = 30.seconds

  # Sentinel for caching non-existent keys. Custom class so it can be
  # marshaled across cache stores without colliding with real values.
  class CacheMiss
    def ==(other)
      other.is_a?(CacheMiss)
    end

    def _dump(_level)
      "site_setting_cache_miss"
    end

    def self._load(_str)
      new
    end
  end
  CACHE_MISS = CacheMiss.new.freeze

  class << self
    # Get a setting value by key.
    # Returns the cached value if available, otherwise fetches from DB.
    # Caches misses to avoid repeated queries for non-existent keys.
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

    # Set a setting value by key.
    # Rescues RecordNotUnique to handle the race where a concurrent
    # request inserts the same key between find_by and save!.
    # Skips the write if the value already matches (compare-and-swap).
    def set(key, value, retries: 3)
      key = key.to_s
      value = value.to_s
      setting = find_or_initialize_by(key: key)
      return setting.value if !setting.new_record? && setting.value == value
      setting.value = value
      setting.save!
      bust_cache(key)
      setting.value
    rescue ActiveRecord::RecordNotUnique
      raise if (retries -= 1) < 0
      retry
    end

    # Convenience method for boolean settings
    def enabled?(key)
      get(key, default: "false") == "true"
    end

    # Security-critical: always read fresh from DB, bypassing cache.
    def registration_enabled?
      (find_by(key: "registration_enabled")&.value || "true") == "true"
    end

    private

    def bust_cache(key)
      Rails.cache.delete("site_setting:#{key}")
    end
  end
end
