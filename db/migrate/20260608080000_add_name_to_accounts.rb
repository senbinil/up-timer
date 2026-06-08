class AddNameToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :name, :string
  end
end
