class AddDashboardLimitToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :dashboard_limit, :integer, default: 3, null: false
  end
end
