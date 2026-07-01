class AddAlertTriggerAndEmailToAlerts < ActiveRecord::Migration[8.1]
  def change
    add_reference :alerts, :alert_trigger, null: true, foreign_key: true
    add_column :alerts, :resolved_at, :datetime
  end
end
