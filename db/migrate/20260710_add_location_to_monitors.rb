class AddLocationToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :latitude, :decimal, precision: 10, scale: 7
    add_column :monitors, :longitude, :decimal, precision: 10, scale: 7
  end
end
