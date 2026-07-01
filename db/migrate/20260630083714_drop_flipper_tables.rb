class DropFlipperTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :flipper_features, if_exists: true
    drop_table :flipper_gates, if_exists: true
  end
end
