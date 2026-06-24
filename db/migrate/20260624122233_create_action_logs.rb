class CreateActionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :action_logs do |t|
      t.string :action, null: false
      t.string :record_type, null: false
      t.integer :record_id, null: false
      t.references :account, null: true, foreign_key: { to_table: :accounts }
      t.json :metadata, null: true

      t.timestamps
    end

    add_index :action_logs, [ :record_type, :record_id ]
    add_index :action_logs, :created_at
  end
end
