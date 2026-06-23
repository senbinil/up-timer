class AddTagsToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :tags, :json, default: [], null: false
  end
end
