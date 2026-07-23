class CreateWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_endpoints do |t|
      t.string :url, null: false
      t.string :token_digest, null: false
      t.string :token_prefix, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_delivered_at

      t.timestamps
    end
  end
end
