class CreateRecipients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipients do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :recipients, :email, unique: true
  end
end
