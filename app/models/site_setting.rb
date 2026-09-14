class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true, length: { minimum: 1 }

  class << self
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
      setting.value
    rescue ActiveRecord::RecordNotUnique
      raise if (retries -= 1) < 1
      sleep(0.1 * (4 - retries))
      retry
    end

    # Security-critical setting: reads directly from DB to enforce
    # immediately across all app instances.
    def registration_enabled?
      (find_by(key: "registration_enabled")&.value || "true") == "true"
    end
  end
end
