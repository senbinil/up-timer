class ChangeDownThresholdDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :monitors, :down_threshold, from: 1, to: 2
  end
end
