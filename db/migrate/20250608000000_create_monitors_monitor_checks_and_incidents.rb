class CreateMonitorsMonitorChecksAndIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :monitors do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.integer :check_interval, null: false
      t.integer :timeout, null: false
      t.string :status, null: false, default: "unknown"

      t.timestamps
    end

    create_table :monitor_checks do |t|
      t.references :monitor, null: false, foreign_key: true
      t.string :status, null: false
      t.float :response_time
      t.integer :status_code
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :monitor_checks, :checked_at

    create_table :incidents do |t|
      t.references :monitor, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :incidents, :started_at
  end
end
