class RenameTokenDigestToTokenInWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    rename_column :webhook_endpoints, :token_digest, :token
    change_column_null :webhook_endpoints, :token, false
  end
end
