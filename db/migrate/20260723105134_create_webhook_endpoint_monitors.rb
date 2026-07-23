class CreateWebhookEndpointMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_endpoint_monitors do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.references :monitor, null: false, foreign_key: { to_table: :monitors }
      t.string :events, default: "check_result,status_change", null: false

      t.timestamps
    end
    add_index :webhook_endpoint_monitors, [ :webhook_endpoint_id, :monitor_id ], unique: true, name: "idx_webhook_endpoint_monitors_on_pair"
  end
end
