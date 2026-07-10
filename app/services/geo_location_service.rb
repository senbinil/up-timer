require "net/http"
require "uri"
require "json"
require "resolv"

class GeoLocationService
  Result = Struct.new(:latitude, :longitude, :success, keyword_init: true)

  # Free tier: 45 requests per minute from one IP. More than enough for
  # occasional monitor creation / URL changes.
  API_URL = "http://ip-api.com/json/%{ip}?fields=status,lat,lon"

  # RFC 1918 private IPv4 ranges
  PRIVATE_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16")
  ].freeze

  def self.call(url)
    new(url).call
  end

  def initialize(url)
    @url = url
  end

  def call
    ip = resolve_hostname
    return failure("could not resolve hostname") unless ip
    return failure("private IP — skipping geolocation") if private_ip?(ip)

    data = fetch_location(ip)
    return failure("api returned #{data["status"]}") unless data["status"] == "success"

    Result.new(
      latitude: data["lat"].to_f,
      longitude: data["lon"].to_f,
      success: true
    )
  end

  private

  def resolve_hostname
    host = URI.parse(@url).host
    return nil unless host

    Resolv.getaddress(host)
  rescue Resolv::ResolvError, URI::InvalidURIError
    nil
  end

  def fetch_location(ip)
    uri = URI(format(API_URL, ip: ip))
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue StandardError
    { "status" => "fail" }
  end

  def private_ip?(ip)
    addr = IPAddr.new(ip)
    addr.loopback? ||
      PRIVATE_RANGES.any? { |range| range.include?(addr) } ||
      addr.ipv6_linklocal? ||
      addr.ipv6_unique_local?
  rescue IPAddr::InvalidAddressError
    true
  end

  def failure(reason)
    Result.new(success: false)
  end
end
