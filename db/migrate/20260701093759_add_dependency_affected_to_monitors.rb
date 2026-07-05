class AddDependencyAffectedToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :dependency_affected, :boolean, default: false, null: false
  end
end
