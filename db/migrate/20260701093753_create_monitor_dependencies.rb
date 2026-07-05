class CreateMonitorDependencies < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_dependencies do |t|
      t.references :monitor, null: false, foreign_key: true
      t.references :dependency, null: false, foreign_key: { to_table: :monitors }

      t.timestamps
    end

    add_index :monitor_dependencies, [ :monitor_id, :dependency_id ], unique: true
  end
end
