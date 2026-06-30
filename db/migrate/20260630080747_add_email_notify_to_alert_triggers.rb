class AddEmailNotifyToAlertTriggers < ActiveRecord::Migration[8.1]
  def change
    add_column :alert_triggers, :email_notify, :boolean, default: false, null: false
  end
end
