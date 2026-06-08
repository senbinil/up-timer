class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.string :severity, null: false, default: "info"
      t.text :message, null: false
      t.references :monitor, foreign_key: true, null: true
      t.boolean :resolved, null: false, default: false

      t.timestamps
    end

    add_index :alerts, :severity
    add_index :alerts, :resolved
  end
end
