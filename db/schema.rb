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

ActiveRecord::Schema.define(version: 20150311164337) do

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

  create_table "billing_attempts", force: true do |t|
    t.integer  "bill_id"
    t.integer  "payment_method_details_id"
    t.integer  "status"
    t.string   "response"
    t.datetime "created_at"
  end

  add_index "billing_attempts", ["bill_id"], name: "index_billing_attempts_on_bill_id", using: :btree
  add_index "billing_attempts", ["payment_method_details_id"], name: "index_billing_attempts_on_payment_method_details_id", using: :btree

  create_table "billing_logs", force: true do |t|
    t.text     "message"
    t.text     "source_file"
    t.datetime "created_at"
    t.integer  "user_id"
    t.integer  "site_id"
    t.integer  "subscription_id"
    t.integer  "payment_method_id"
    t.integer  "payment_method_details_id"
    t.integer  "bill_id"
    t.integer  "billing_attempt_id"
  end

  add_index "billing_logs", ["bill_id"], name: "index_billing_logs_on_bill_id", using: :btree
  add_index "billing_logs", ["billing_attempt_id"], name: "index_billing_logs_on_billing_attempt_id", using: :btree
  add_index "billing_logs", ["created_at"], name: "index_billing_logs_on_created_at", using: :btree
  add_index "billing_logs", ["payment_method_details_id"], name: "index_billing_logs_on_payment_method_details_id", using: :btree
  add_index "billing_logs", ["payment_method_id"], name: "index_billing_logs_on_payment_method_id", using: :btree
  add_index "billing_logs", ["site_id"], name: "index_billing_logs_on_site_id", using: :btree
  add_index "billing_logs", ["subscription_id"], name: "index_billing_logs_on_subscription_id", using: :btree
  add_index "billing_logs", ["user_id"], name: "index_billing_logs_on_user_id", using: :btree

  create_table "bills", force: true do |t|
    t.integer  "subscription_id"
    t.integer  "status",                                       default: 0
    t.string   "type"
    t.decimal  "amount",               precision: 7, scale: 2
    t.string   "description"
    t.string   "metadata"
    t.boolean  "grace_period_allowed",                         default: true
    t.datetime "bill_at"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "status_set_at"
    t.datetime "created_at"
  end

  add_index "bills", ["status", "bill_at"], name: "index_bills_on_status_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "status", "bill_at"], name: "index_bills_on_subscription_id_and_status_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "type", "bill_at"], name: "index_bills_on_subscription_id_and_type_and_bill_at", using: :btree
  add_index "bills", ["type", "bill_at"], name: "index_bills_on_type_and_bill_at", using: :btree

  create_table "conditions", force: true do |t|
    t.integer  "rule_id"
    t.string   "segment",    null: false
    t.string   "operand",    null: false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "conditions", ["rule_id"], name: "index_conditions_on_rule_id", using: :btree

  create_table "contact_lists", force: true do |t|
    t.integer  "site_id"
    t.integer  "identity_id"
    t.string   "name"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "double_optin", default: true
  end

  add_index "contact_lists", ["identity_id"], name: "index_contact_lists_on_identity_id", using: :btree
  add_index "contact_lists", ["site_id"], name: "index_contact_lists_on_site_id", using: :btree

  create_table "identities", force: true do |t|
    t.integer  "site_id"
    t.string   "provider"
    t.text     "credentials"
    t.text     "extra"
    t.text     "embed_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "improve_suggestions", force: true do |t|
    t.integer  "site_id"
    t.string   "name"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "improve_suggestions", ["site_id", "name", "updated_at"], name: "index_improve_suggestions_on_site_id_and_name_and_updated_at", using: :btree

  create_table "internal_processing", id: false, force: true do |t|
    t.integer "last_updated_at",                null: false
    t.integer "last_event_processed",           null: false
    t.integer "last_prop_processed",            null: false
    t.integer "last_visitor_user_id_processed", null: false
  end

  create_table "payment_method_details", force: true do |t|
    t.integer  "payment_method_id"
    t.string   "type"
    t.text     "data"
    t.datetime "created_at"
  end

  add_index "payment_method_details", ["payment_method_id"], name: "index_payment_method_details_on_payment_method_id", using: :btree

  create_table "payment_methods", force: true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "payment_methods", ["deleted_at"], name: "index_payment_methods_on_deleted_at", using: :btree
  add_index "payment_methods", ["user_id"], name: "index_payment_methods_on_user_id", using: :btree

  create_table "rules", force: true do |t|
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "priority"
    t.string   "match"
    t.boolean  "editable",   default: true
  end

  add_index "rules", ["site_id"], name: "index_rules_on_site_id", using: :btree

  create_table "site_elements", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "element_subtype",                                                           null: false
    t.string   "target_segment"
    t.boolean  "closable",                        default: false
    t.boolean  "show_border",                     default: false
    t.string   "background_color",                default: "eb593c"
    t.string   "border_color",                    default: "ffffff"
    t.string   "button_color",                    default: "000000"
    t.string   "font",                            default: "Helvetica,Arial,sans-serif"
    t.string   "link_color",                      default: "ffffff"
    t.string   "link_style",                      default: "button"
    t.string   "link_text",          limit: 5000, default: "Click Here"
    t.string   "headline",           limit: 5000, default: "Hello. Add your message here."
    t.string   "size",                            default: "large"
    t.string   "target"
    t.string   "text_color",                      default: "ffffff"
    t.string   "texture",                         default: "none"
    t.boolean  "paused",                          default: false
    t.integer  "rule_id"
    t.text     "settings"
    t.boolean  "show_branding",                   default: true
    t.integer  "contact_list_id"
    t.string   "display_when",                    default: "immediately"
    t.string   "thank_you_text"
    t.boolean  "pushes_page_down",                default: true
    t.boolean  "remains_at_top",                  default: true
    t.boolean  "open_in_new_window",              default: false
    t.boolean  "animated",                        default: false
    t.boolean  "wiggle_button",                   default: false
    t.integer  "wordpress_bar_id"
    t.string   "type",                            default: "Bar"
    t.string   "caption",                         default: ""
    t.string   "modal_placement",                 default: "middle"
    t.string   "slider_placement",                default: "bottom-right"
  end

  add_index "site_elements", ["contact_list_id"], name: "index_site_elements_on_contact_list_id", using: :btree
  add_index "site_elements", ["element_subtype"], name: "index_site_elements_on_element_subtype", using: :btree
  add_index "site_elements", ["rule_id"], name: "index_site_elements_on_rule_id", using: :btree

  create_table "site_memberships", force: true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.string   "role",       default: "owner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "site_memberships", ["site_id"], name: "index_site_memberships_on_site_id", using: :btree
  add_index "site_memberships", ["user_id"], name: "index_site_memberships_on_user_id", using: :btree

  create_table "sites", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.boolean  "opted_in_to_email_digest",        default: true
    t.datetime "script_installed_at"
    t.datetime "script_generated_at"
    t.datetime "script_attempted_to_generate_at"
    t.string   "read_key"
    t.string   "write_key"
    t.string   "timezone"
    t.datetime "deleted_at"
    t.datetime "script_uninstalled_at"
  end

  add_index "sites", ["created_at"], name: "index_sites_on_created_at", using: :btree

  create_table "subscriptions", force: true do |t|
    t.integer  "user_id"
    t.integer  "site_id"
    t.string   "type"
    t.integer  "schedule",                                     default: 0
    t.decimal  "amount",               precision: 7, scale: 2
    t.integer  "visit_overage"
    t.integer  "visit_overage_unit"
    t.decimal  "visit_overage_amount", precision: 5, scale: 2
    t.datetime "created_at"
    t.integer  "payment_method_id"
  end

  add_index "subscriptions", ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
  add_index "subscriptions", ["payment_method_id"], name: "index_subscriptions_on_payment_method_id", using: :btree
  add_index "subscriptions", ["site_id"], name: "index_subscriptions_on_site_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",       null: false
    t.string   "encrypted_password",     default: "",       null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,        null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "status",                 default: "active"
    t.datetime "deleted_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
