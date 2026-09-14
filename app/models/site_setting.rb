class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true, length: { minimum: 1 }

  CACHE_TTL = 30.seconds

  # Empty string sentinel: validation guarantees non-empty values,
  # so "" is safe across all serializer backends (Marshal, JSON, etc.).
  CACHE_MISS = "".freeze

  class << self
    # Get a setting value by key.
    # Returns the cached value if available, otherwise fetches from DB.
    # Caches misses to avoid repeated queries for non-existent keys.
    def get(key, default: nil)
      key = key.to_s
      cache_key = "site_setting:#{key}"
      cached = Rails.cache.read(cache_key)

      return default if cached == CACHE_MISS
      return cached unless cached.nil?

      setting = find_by(key: key)
      if setting
        Rails.cache.write(cache_key, setting.value, expires_in: CACHE_TTL)
        setting.value
      else
        Rails.cache.write(cache_key, CACHE_MISS, expires_in: CACHE_TTL)
        default
      end
    end

    # Set a setting value by key.
    # Rescues RecordNotUnique to handle the race where a concurrent
    # request inserts the same key between find_by and save!.
    # Skips the write if the in-memory value already matches.
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
      raise if (retries -= 1) < 1
      sleep(0.1 * (4 - retries))
      retry
    end

    # Convenience method for boolean settings
    def enabled?(key)
      get(key, default: "false") == "true"
    end

    # Security-critical setting: reads directly from DB to enforce
    # immediately across all app instances. No cache — the DB hit
    # is negligible and correctness matters more here.
    def registration_enabled?
      get("registration_enabled", default: "true") == "true"
    end

    private

    def bust_cache(key)
      Rails.cache.delete("site_setting:#{key}")
    end
  end
end
