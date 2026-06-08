class RemoveDashboardLimitFromAccounts < ActiveRecord::Migration[8.1]
  def change
    remove_column :accounts, :dashboard_limit, :integer
  end
end
