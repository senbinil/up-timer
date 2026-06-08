class AddPositionToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :position, :integer, default: 0, null: false
    add_index :monitors, :position
  end
end
