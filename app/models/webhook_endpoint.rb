class WebhookEndpoint < ApplicationRecord
  has_many :webhook_endpoint_monitors, dependent: :destroy
  has_many :monitors, through: :webhook_endpoint_monitors, class_name: "UptimeMonitor"

  before_validation :set_token_prefix, on: :create

  validates :url, presence: true, format: { with: /\Ahttps?:\/\/.+\z/, message: "must be a valid HTTP(S) URL" }
  validates :token, presence: true

  scope :active, -> { where(active: true) }

  def masked_url
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port != uri.default_port}/***"
  rescue URI::InvalidURIError
    url
  end

  def masked_token
    return "" unless token.present?
    token.length > 8 ? "#{token.first(8)}..." : "***"
  end

  private

  def set_token_prefix
    self.token_prefix = token&.first(8) || "****"
  end
end
