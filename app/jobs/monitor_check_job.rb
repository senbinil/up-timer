require "net/http"
require "uri"

class MonitorCheckJob < ApplicationJob
  queue_as :default

  def perform(monitor_id)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor

    url = monitor.url
    start = Time.current
    response = perform_check(url, monitor.timeout)

    status = response.code.to_i.between?(200, 399) ? "up" : "down"
    response_time = ((Time.current - start) * 1000).round(2)

    monitor.update!(status: status)
    monitor.monitor_checks.create!(
      status: status,
      response_time: response_time,
      status_code: response.code&.to_i,
      checked_at: Time.current
    )

    if status == "down" && monitor.incidents.where(resolved_at: nil).none?
      monitor.incidents.create!(started_at: Time.current)
    elsif status == "up"
      monitor.incidents.where(resolved_at: nil).update_all(resolved_at: Time.current)
    end
  end

  private

  def perform_check(url, timeout)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = timeout
    http.read_timeout = timeout
    http.use_ssl = uri.scheme == "https"
    http.start { |conn| conn.get(uri.request_uri) }
  rescue StandardError => e
    Struct.new(:code, :message).new(nil, e.message)
  end
end
