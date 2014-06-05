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

ActiveRecord::Schema.define(version: 20140605195609) do

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

  create_table "bars", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "goal",                                                         null: false
    t.string   "target_segment"
    t.boolean  "closable",           default: false
    t.boolean  "hide_destination",   default: false
    t.boolean  "open_in_new_window", default: false
    t.boolean  "pushes_page_down",   default: false
    t.boolean  "remains_at_top",     default: false
    t.boolean  "show_border",        default: false
    t.integer  "hide_after",         default: 0
    t.integer  "show_wait"
    t.integer  "wiggle_wait",        default: 0
    t.string   "bar_color",          default: "eb593c"
    t.string   "border_color",       default: "ffffff"
    t.string   "button_color",       default: "000000"
    t.string   "font",               default: "Helvetica,Arial,sans-serif"
    t.string   "link_color",         default: "ffffff"
    t.string   "link_style",         default: "button"
    t.string   "link_text",          default: "Click Here"
    t.string   "message",            default: "Hello. Add your message here."
    t.string   "size",               default: "large"
    t.string   "tab_side",           default: "right"
    t.string   "target"
    t.string   "text_color",         default: "ffffff"
    t.string   "texture",            default: "none"
    t.string   "thank_you_text",     default: "Thank you for signing up!"
    t.boolean  "paused",             default: false
    t.integer  "rule_set_id"
  end

  add_index "bars", ["goal"], name: "index_bars_on_goal", using: :btree
  add_index "bars", ["rule_set_id"], name: "index_bars_on_rule_set_id", using: :btree

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

  create_table "rule_sets", force: true do |t|
    t.datetime "end_date"
    t.datetime "start_date"
    t.text     "include_urls"
    t.text     "exclude_urls"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rule_sets", ["site_id"], name: "index_rule_sets_on_site_id", using: :btree

  create_table "rules", force: true do |t|
    t.integer "rule_set_id"
  end

  add_index "rules", ["rule_set_id"], name: "index_rules_on_rule_set_id", using: :btree

  create_table "site_memberships", force: true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.string   "role",       default: "owner"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_memberships", ["site_id"], name: "index_site_memberships_on_site_id", using: :btree
  add_index "site_memberships", ["user_id"], name: "index_site_memberships_on_user_id", using: :btree

  create_table "sites", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.boolean  "opted_in_to_email_digest", default: true
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
