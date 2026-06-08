# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_06_08_000000) do
  create_table "incidents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "monitor_id", null: false
    t.datetime "resolved_at"
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["monitor_id"], name: "index_incidents_on_monitor_id"
    t.index ["started_at"], name: "index_incidents_on_started_at"
  end

  create_table "monitor_checks", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.integer "monitor_id", null: false
    t.float "response_time"
    t.string "status", null: false
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.index ["checked_at"], name: "index_monitor_checks_on_checked_at"
    t.index ["monitor_id"], name: "index_monitor_checks_on_monitor_id"
  end

  create_table "monitors", force: :cascade do |t|
    t.integer "check_interval", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "unknown", null: false
    t.integer "timeout", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
  end

  add_foreign_key "incidents", "monitors"
  add_foreign_key "monitor_checks", "monitors"
end
