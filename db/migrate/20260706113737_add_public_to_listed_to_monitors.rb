class AddPublicToListedToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :public_listed, :boolean
  end
end
