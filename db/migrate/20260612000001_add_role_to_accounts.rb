class AddRoleToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :role, :string, null: false, default: "viewer"
  end
end
