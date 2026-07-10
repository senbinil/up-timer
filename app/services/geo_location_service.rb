require "net/http"
require "uri"
require "json"
require "resolv"

class GeoLocationService
  Result = Struct.new(:latitude, :longitude, :success, keyword_init: true)

  # Free tier: 45 requests per minute from one IP. More than enough for
  # occasional monitor creation / URL changes.
  API_URL = "http://ip-api.com/json/%{ip}?fields=status,lat,lon"

  # Non-routable IP ranges that should not be geolocated
  LOCAL_RANGES = [
    IPAddr.new("127.0.0.0/8"),       # loopback
    IPAddr.new("::1/128"),             # IPv6 loopback
    IPAddr.new("10.0.0.0/8"),         # RFC 1918 private
    IPAddr.new("172.16.0.0/12"),      # RFC 1918 private
    IPAddr.new("192.168.0.0/16"),     # RFC 1918 private
    IPAddr.new("169.254.0.0/16"),    # IPv4 link-local
    IPAddr.new("fe80::/10"),           # IPv6 link-local
    IPAddr.new("fc00::/7")            # IPv6 unique-local
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
    LOCAL_RANGES.any? { |range| range.include?(addr) }
  rescue IPAddr::InvalidAddressError
    true
  end

  def failure(reason)
    Result.new(success: false)
  end
end
