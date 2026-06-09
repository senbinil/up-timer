class AddRequestFieldsToMonitors < ActiveRecord::Migration[8.1]
  def change
    add_column :monitors, :request_type, :string, null: false, default: "GET"
    add_column :monitors, :expected_status, :integer
    add_column :monitors, :request_body, :text
  end
end
