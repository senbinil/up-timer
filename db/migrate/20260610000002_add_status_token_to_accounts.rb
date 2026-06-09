class AddStatusTokenToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :status_token, :string
    add_index :accounts, :status_token, unique: true
  end
end
