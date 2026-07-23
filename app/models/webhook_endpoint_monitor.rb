class WebhookEndpointMonitor < ApplicationRecord
  belongs_to :webhook_endpoint
  belongs_to :monitor, class_name: "UptimeMonitor"

  validates :events, presence: true

  EVENT_TYPES = %w[check_result status_change].freeze

  def event_list
    (events || "").split(",").map(&:strip)
  end

  def sends_event?(event_type)
    event_list.include?(event_type.to_s)
  end
end
