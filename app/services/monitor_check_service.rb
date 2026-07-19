require "ostruct"
require "net/http"
require "uri"

class MonitorCheckService
  SUPPORTED_METHODS = %w[GET HEAD POST PUT PATCH DELETE OPTIONS].freeze
  BODY_METHODS = %w[POST PUT PATCH].freeze

  Result = Struct.new(:code, :message, :up, :duration,
                      :ssl_valid, :ssl_expires_at, :ssl_issuer, :ssl_subject,
                      keyword_init: true)

  def self.call(monitor)
    new(monitor).call
  end

  def initialize(monitor)
    @monitor = monitor
    @url = monitor.url
    @method = monitor.request_type || "GET"
    @timeout = monitor.timeout
    @body = monitor.request_body
    @expected = monitor.expected_status
  end

  def call
    start = Time.current
    http, request = build_request
    response = http.request(request)
    duration = ((Time.current - start) * 1000).round(2)

    code = response.code.to_i
    up = determine_up(code)

    Result.new(
      code: code,
      message: response.message,
      up: up,
      duration: duration,
      **ssl_info(http)
    )
  rescue StandardError => e
    Result.new(
      code: nil,
      message: e.message,
      up: false,
      duration: 0
    )
  end

  private

  def build_request
    uri = URI(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = @timeout
    http.read_timeout = @timeout
    http.write_timeout = @timeout if http.respond_to?(:write_timeout=)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP.const_get(@method.capitalize).new(uri)
    request["Content-Type"] = "application/json"
    request.body = @body if BODY_METHODS.include?(@method) && @body.present?

    [http, request]
  end

  def ssl_info(http)
    return {} unless http.use_ssl?

    cert = http.peer_cert
    return {} unless cert

    expires = cert.not_after
    {
      ssl_valid: Time.current.between?(cert.not_before, expires),
      ssl_expires_at: expires,
      ssl_issuer: cert.issuer.to_s,
      ssl_subject: cert.subject.to_s
    }
  rescue StandardError
    {}
  end

  def determine_up(code)
    return false if code.nil? || code.zero?
    @expected.present? ? code == @expected : code.between?(200, 399)
  end
end
