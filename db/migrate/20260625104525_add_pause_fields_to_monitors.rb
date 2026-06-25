class AddPauseFieldsToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :paused, :boolean, default: false, null: false
  end
end
