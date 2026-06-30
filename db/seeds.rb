# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

AlertTrigger.find_or_create_by!(name: "Critical Errors") do |t|
  t.description = "Immediately notify recipients when a system-wide fatal exception occurs or core services fail to respond for more than 30 seconds."
  t.severity = "critical"
  t.email_notify = true
end

AlertTrigger.find_or_create_by!(name: "Degraded Performance") do |t|
  t.description = "Triggered when latency exceeds P99 thresholds (500ms) for a continuous period of 5 minutes across any regional cluster."
  t.severity = "warning"
  t.email_notify = false
end

AlertTrigger.find_or_create_by!(name: "Node Offline") do |t|
  t.description = "Sent when a primary compute node stops heartbeating. Includes specific node metadata and last known health telemetry in the payload."
  t.severity = "critical"
  t.email_notify = true
end

AlertTrigger.find_or_create_by!(name: "Security Breach") do |t|
  t.description = "High-priority alert for unauthorized access attempts, SSH brute force detection, or unexpected privilege escalation logs."
  t.severity = "critical"
  t.email_notify = true
end

AlertTrigger.find_or_create_by!(name: "Maintenance Window") do |t|
  t.description = "Notify recipients 30 minutes prior to scheduled maintenance start and immediately upon service restoration."
  t.severity = "maintenance"
  t.email_notify = false
end

AlertTrigger.find_or_create_by!(name: "Custom") do |t|
  t.description = "Manual alert created by a user for any ad-hoc notification."
  t.severity = "info"
  t.email_notify = true
end
