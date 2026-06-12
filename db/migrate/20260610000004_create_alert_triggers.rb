class CreateAlertTriggers < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_triggers do |t|
      t.string :name, null: false
      t.text :description
      t.string :severity, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
