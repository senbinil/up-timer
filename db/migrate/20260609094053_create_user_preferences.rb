class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.integer :dashboard_limit, default: 3, null: false
      t.timestamps
    end
  end
end
