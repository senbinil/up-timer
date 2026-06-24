class AddAccountIdToAlerts < ActiveRecord::Migration[8.1]
  def change
    add_reference :alerts, :account, null: true, foreign_key: { to_table: :accounts }
    add_reference :alerts, :resolved_by, null: true, foreign_key: { to_table: :accounts }
  end
end
