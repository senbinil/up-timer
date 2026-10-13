class AddAlertToIncidents < ActiveRecord::Migration[8.1]
  def change
    add_reference :incidents, :alert, null: true, foreign_key: { to_table: :alerts, on_delete: :nullify }
  end
end
