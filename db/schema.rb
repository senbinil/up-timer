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

ActiveRecord::Schema[8.1].define(version: 2026_06_08_080000) do
  create_table "account_login_change_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.string "key", null: false
    t.string "login", null: false
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "key", null: false
  end

  create_table "account_remember_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.string "key", null: false
  end

  create_table "account_verification_keys", force: :cascade do |t|
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "password_hash"
    t.integer "status", default: 1, null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true, where: "status IN (1, 2)"
  end

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

  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "incidents", "monitors"
  add_foreign_key "monitor_checks", "monitors"
end
