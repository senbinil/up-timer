class GeoLocationJob < ApplicationJob
  queue_as :default

  def perform(monitor_id)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor
    return if monitor.url.blank?

    result = GeoLocationService.call(monitor.url)

    if result.success
      monitor.update_columns(latitude: result.latitude, longitude: result.longitude)
    else
      monitor.update_columns(latitude: nil, longitude: nil)
    end
  end
end
