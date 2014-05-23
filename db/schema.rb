# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140523042541) do

  create_table "admin_login_attempts", force: true do |t|
    t.string   "email"
    t.string   "ip_address"
    t.string   "user_agent"
    t.string   "access_cookie"
    t.datetime "attempted_at"
  end

  create_table "admins", force: true do |t|
    t.string   "email"
    t.string   "mobile_phone"
    t.string   "password_hashed"
    t.string   "mobile_code"
    t.string   "session_token"
    t.string   "session_access_token"
    t.string   "permissions_json"
    t.datetime "password_last_reset"
    t.datetime "session_last_active"
    t.integer  "mobile_codes_sent",                  default: 0
    t.integer  "login_attempts",                     default: 0
    t.string   "valid_access_tokens",  limit: 18000
    t.boolean  "locked",                             default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["session_token", "session_access_token"], name: "index_admins_on_session_token_and_session_access_token", using: :btree

  create_table "bar_settings", force: true do |t|
    t.boolean  "closable",           default: false
    t.boolean  "hide_destination",   default: false
    t.boolean  "open_in_new_window", default: false
    t.boolean  "pushes_page_down",   default: false
    t.boolean  "remains_at_top",     default: false
    t.boolean  "show_border",        default: false
    t.integer  "hide_after"
    t.integer  "show_wait"
    t.integer  "wiggle_wait"
    t.string   "bar_color"
    t.string   "border_color"
    t.string   "button_color"
    t.string   "font"
    t.string   "link_color"
    t.string   "link_style"
    t.string   "link_text"
    t.string   "message"
    t.string   "size"
    t.string   "tab_side"
    t.string   "target"
    t.string   "text_color"
    t.string   "texture"
    t.string   "thank_you_text"
    t.integer  "bar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bar_settings", ["bar_id"], name: "index_bar_settings_on_bar_id", unique: true, using: :btree

  create_table "bars", force: true do |t|
    t.integer  "rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "goal",           null: false
    t.string   "target_segment"
  end

  add_index "bars", ["goal"], name: "index_bars_on_goal", using: :btree
  add_index "bars", ["rule_id"], name: "index_bars_on_rule_id", using: :btree

  create_table "internal_dimensions", force: true do |t|
    t.integer "person_id",              null: false
    t.string  "name",      default: "", null: false
    t.string  "value"
    t.integer "timestamp"
  end

  add_index "internal_dimensions", ["name", "timestamp"], name: "index_internal_dimensions_on_name_and_timestamp", using: :btree
  add_index "internal_dimensions", ["name", "value"], name: "index_internal_dimensions_on_name_and_value", using: :btree

  create_table "internal_events", force: true do |t|
    t.integer "timestamp"
    t.string  "target_type"
    t.string  "name"
    t.string  "target_id",   limit: 40
  end

  add_index "internal_events", ["target_type", "name"], name: "index_internal_events_on_target_type_and_name", using: :btree

  create_table "internal_people", force: true do |t|
    t.string  "visitor_id",                limit: 40
    t.integer "user_id"
    t.integer "account_id"
    t.integer "first_visited_at"
    t.integer "signed_up_at"
    t.integer "completed_registration_at"
    t.integer "created_first_bar_at"
    t.integer "created_second_bar_at"
    t.integer "received_data_at"
  end

  add_index "internal_people", ["account_id"], name: "index_internal_people_on_account_id", using: :btree
  add_index "internal_people", ["first_visited_at"], name: "index_internal_people_on_first_visited_at", using: :btree
  add_index "internal_people", ["signed_up_at"], name: "index_internal_people_on_signed_up_at", using: :btree
  add_index "internal_people", ["user_id"], name: "index_internal_people_on_user_id", using: :btree
  add_index "internal_people", ["visitor_id"], name: "index_internal_people_on_visitor_id", using: :btree

  create_table "internal_processing", force: true do |t|
    t.integer "last_updated_at",                null: false
    t.integer "last_event_processed",           null: false
    t.integer "last_prop_processed",            null: false
    t.integer "last_visitor_user_id_processed", null: false
  end

  create_table "internal_props", force: true do |t|
    t.integer "timestamp"
    t.string  "target_type"
    t.string  "name"
    t.string  "value"
    t.string  "target_id",   limit: 40
  end

  add_index "internal_props", ["target_type", "name", "value"], name: "index_internal_props_on_target_type_and_name_and_value", using: :btree

  create_table "internal_reports", force: true do |t|
    t.string   "name"
    t.text     "data",       limit: 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "internal_reports", ["name"], name: "index_internal_reports_on_name", using: :btree

  create_table "rule_settings", force: true do |t|
    t.datetime "end_date"
    t.datetime "start_date"
    t.text     "exclude_urls"
    t.text     "include_urls"
    t.integer  "rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rule_settings", ["rule_id"], name: "index_rule_settings_on_rule_id", unique: true, using: :btree

  create_table "rules", force: true do |t|
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rules", ["site_id"], name: "index_rules_on_site_id", using: :btree

  create_table "sites", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
