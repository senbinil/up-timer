class RemoveActiveFromAlertTriggers < ActiveRecord::Migration[8.1]
  def change
    remove_column :alert_triggers, :active, :boolean
  end
end
