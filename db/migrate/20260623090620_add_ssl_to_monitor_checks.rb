class AddSslToMonitorChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :monitor_checks, :ssl_valid, :boolean
    add_column :monitor_checks, :ssl_expires_at, :datetime
    add_column :monitor_checks, :ssl_issuer, :string
    add_column :monitor_checks, :ssl_subject, :string
  end
end
