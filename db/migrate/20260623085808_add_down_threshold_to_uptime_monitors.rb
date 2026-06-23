class AddDownThresholdToUptimeMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :down_threshold, :integer, default: 1, null: false
  end
end
