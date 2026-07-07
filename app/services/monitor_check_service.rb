require "ostruct"

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
    response = perform_http_request
    duration = ((Time.current - start) * 1000).round(2)

    code = response.code&.to_i
    up = determine_up(code)

    Result.new(
      code: code,
      message: response.message,
      up: up,
      duration: duration,
      **ssl_info(response)
    )
  end

  private

  def ssl_info(response)
    cert = response.respond_to?(:peer_cert) ? response.peer_cert : nil
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

  def perform_http_request
    uri = URI(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = @timeout
    http.read_timeout = @timeout
    http.use_ssl = uri.scheme == "https"

    request = build_request(uri)
    http.start { |conn| conn.request(request) }
  rescue StandardError => e
    OpenStruct.new(code: nil, message: e.message)
  end

  def build_request(uri)
    klass = Net::HTTP.const_get(@method.capitalize)
    req = klass.new(uri.request_uri, { "Content-Type" => "application/json" })

    req.body = @body if BODY_METHODS.include?(@method) && @body.present?

    req
  end

  def determine_up(code)
    return false if code.nil?
    @expected.present? ? code == @expected : code.between?(200, 399)
  end
end
