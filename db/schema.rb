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

ActiveRecord::Schema.define(version: 20140519174141) do

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

end
