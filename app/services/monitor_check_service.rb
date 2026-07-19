require "ostruct"
require "httpx"
require "socket"

class MonitorCheckService
  SUPPORTED_METHODS = %w[GET HEAD POST PUT PATCH DELETE OPTIONS].freeze
  BODY_METHODS = %w[POST PUT PATCH].freeze

  Result = Struct.new(:code, :message, :up, :duration,
                      :ssl_valid, :ssl_expires_at, :ssl_issuer, :ssl_subject,
                      keyword_init: true)

  # Shared HTTPX session with connection pooling and retry support
  SESSION = HTTPX.plugin(:retries).with(retries: 1, retry_on_timeout: true)

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
    response = perform_http_request
    duration = ((Time.current - start) * 1000).round(2)

    code = response.status.to_i
    up = determine_up(code)

    Result.new(
      code: code,
      message: Rack::Utils::HTTP_STATUS_CODES[code] || "Unknown",
      up: up,
      duration: duration,
      **ssl_info(response)
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

  def ssl_info(response)
    cert = if response.respond_to?(:certificate)
      response.certificate
    else
      fetch_certificate
    end
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

  def fetch_certificate
    uri = URI(@url)
    return nil unless uri.scheme == "https"

    tcp = TCPSocket.new(uri.host, uri.port || 443)
    ctx = OpenSSL::SSL::SSLContext.new
    sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
    sock.hostname = uri.host
    sock.connect
    cert = sock.peer_cert
    sock.close
    tcp.close
    cert
  rescue StandardError
    nil
  end

  def perform_http_request
    uri = URI(@url)
    headers = { "Content-Type" => "application/json" }

    session = SESSION.with(timeout: { request_timeout: @timeout, connect_timeout: @timeout })

    if BODY_METHODS.include?(@method) && @body.present?
      session.request(@method, uri.to_s, headers: headers, body: @body)
    else
      session.request(@method, uri.to_s, headers: headers)
    end
  end

  def determine_up(code)
    return false if code.nil? || code.zero?
    @expected.present? ? code == @expected : code.between?(200, 399)
  end
end
