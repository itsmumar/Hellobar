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

ActiveRecord::Schema.define(version: 20170608222055) do

  create_table "admin_login_attempts", force: :cascade do |t|
    t.string   "email",         limit: 255
    t.string   "ip_address",    limit: 255
    t.string   "user_agent",    limit: 255
    t.string   "access_cookie", limit: 255
    t.datetime "attempted_at"
  end

  create_table "admins", force: :cascade do |t|
    t.string   "email",               limit: 255
    t.string   "initial_password",    limit: 255
    t.string   "password_hashed",     limit: 255
    t.string   "session_token",       limit: 255
    t.string   "permissions_json",    limit: 255
    t.datetime "password_last_reset"
    t.datetime "session_last_active"
    t.integer  "login_attempts",      limit: 4,   default: 0
    t.boolean  "locked",                          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_token",           limit: 255
    t.string   "authentication_code", limit: 255
    t.string   "rotp_secret_base",    limit: 255
  end

  add_index "admins", ["api_token"], name: "index_admins_on_api_token", using: :btree
  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["session_token"], name: "index_admins_on_session_token", using: :btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "provider",      limit: 255
    t.string   "uid",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "refresh_token", limit: 255
    t.string   "access_token",  limit: 255
    t.datetime "expires_at"
  end

  add_index "authentications", ["uid"], name: "index_authentications_on_uid", using: :btree
  add_index "authentications", ["user_id"], name: "index_authentications_on_user_id", using: :btree

  create_table "autofills", force: :cascade do |t|
    t.integer  "site_id",           limit: 4,   null: false
    t.string   "name",              limit: 255, null: false
    t.string   "listen_selector",   limit: 255, null: false
    t.string   "populate_selector", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "autofills", ["site_id"], name: "index_autofills_on_site_id", using: :btree

  create_table "billing_attempts", force: :cascade do |t|
    t.integer  "bill_id",                   limit: 4
    t.integer  "payment_method_details_id", limit: 4
    t.integer  "status",                    limit: 4
    t.string   "response",                  limit: 255
    t.datetime "created_at"
  end

  add_index "billing_attempts", ["bill_id"], name: "index_billing_attempts_on_bill_id", using: :btree
  add_index "billing_attempts", ["payment_method_details_id"], name: "index_billing_attempts_on_payment_method_details_id", using: :btree

  create_table "billing_logs", force: :cascade do |t|
    t.text     "message",                   limit: 65535
    t.text     "source_file",               limit: 65535
    t.datetime "created_at"
    t.integer  "user_id",                   limit: 4
    t.integer  "site_id",                   limit: 4
    t.integer  "subscription_id",           limit: 4
    t.integer  "payment_method_id",         limit: 4
    t.integer  "payment_method_details_id", limit: 4
    t.integer  "bill_id",                   limit: 4
    t.integer  "billing_attempt_id",        limit: 4
  end

  add_index "billing_logs", ["bill_id"], name: "index_billing_logs_on_bill_id", using: :btree
  add_index "billing_logs", ["billing_attempt_id"], name: "index_billing_logs_on_billing_attempt_id", using: :btree
  add_index "billing_logs", ["created_at"], name: "index_billing_logs_on_created_at", using: :btree
  add_index "billing_logs", ["payment_method_details_id"], name: "index_billing_logs_on_payment_method_details_id", using: :btree
  add_index "billing_logs", ["payment_method_id"], name: "index_billing_logs_on_payment_method_id", using: :btree
  add_index "billing_logs", ["site_id"], name: "index_billing_logs_on_site_id", using: :btree
  add_index "billing_logs", ["subscription_id"], name: "index_billing_logs_on_subscription_id", using: :btree
  add_index "billing_logs", ["user_id"], name: "index_billing_logs_on_user_id", using: :btree

  create_table "bills", force: :cascade do |t|
    t.integer  "subscription_id",      limit: 4
    t.integer  "status",               limit: 4,                            default: 0
    t.string   "type",                 limit: 255
    t.decimal  "amount",                           precision: 7,  scale: 2
    t.string   "description",          limit: 255
    t.string   "metadata",             limit: 255
    t.boolean  "grace_period_allowed",                                      default: true
    t.datetime "bill_at"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "status_set_at"
    t.datetime "created_at"
    t.decimal  "discount",                         precision: 10,           default: 0
    t.decimal  "base_amount",                      precision: 10
    t.integer  "refund_id",            limit: 4
  end

  add_index "bills", ["refund_id"], name: "index_bills_on_refund_id", using: :btree
  add_index "bills", ["status", "bill_at"], name: "index_bills_on_status_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "status", "bill_at"], name: "index_bills_on_subscription_id_and_status_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "type", "bill_at"], name: "index_bills_on_subscription_id_and_type_and_bill_at", using: :btree
  add_index "bills", ["type", "bill_at"], name: "index_bills_on_type_and_bill_at", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.integer  "rule_id",        limit: 4
    t.string   "segment",        limit: 255,   null: false
    t.string   "operand",        limit: 255,   null: false
    t.text     "value",          limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "custom_segment", limit: 255
    t.string   "data_type",      limit: 255
  end

  add_index "conditions", ["rule_id"], name: "index_conditions_on_rule_id", using: :btree

  create_table "contact_list_logs", force: :cascade do |t|
    t.integer  "contact_list_id", limit: 4
    t.string   "email",           limit: 255
    t.string   "name",            limit: 255
    t.text     "error",           limit: 65535
    t.boolean  "completed",                     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "stacktrace",      limit: 65535
  end

  add_index "contact_list_logs", ["contact_list_id"], name: "index_contact_list_logs_on_contact_list_id", using: :btree

  create_table "contact_lists", force: :cascade do |t|
    t.integer  "site_id",      limit: 4
    t.integer  "identity_id",  limit: 4
    t.string   "name",         limit: 255
    t.text     "data",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "double_optin",               default: true
    t.datetime "deleted_at"
  end

  add_index "contact_lists", ["identity_id"], name: "index_contact_lists_on_identity_id", using: :btree
  add_index "contact_lists", ["site_id"], name: "index_contact_lists_on_site_id", using: :btree

  create_table "coupon_uses", force: :cascade do |t|
    t.integer  "coupon_id",  limit: 4
    t.integer  "bill_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "coupons", force: :cascade do |t|
    t.string   "label",          limit: 255
    t.integer  "available_uses", limit: 4
    t.decimal  "amount",                     precision: 7, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                                             default: false
  end

  create_table "identities", force: :cascade do |t|
    t.integer  "site_id",     limit: 4
    t.string   "provider",    limit: 255
    t.text     "credentials", limit: 65535
    t.text     "extra",       limit: 65535
    t.text     "embed_code",  limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key",     limit: 255
  end

  create_table "image_uploads", force: :cascade do |t|
    t.string   "description",        limit: 255
    t.string   "url",                limit: 255
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",            limit: 4
    t.string   "preuploaded_url",    limit: 255
    t.string   "theme_id",           limit: 255
    t.integer  "version",            limit: 4,   default: 2
  end

  add_index "image_uploads", ["site_id"], name: "index_image_uploads_on_site_id", using: :btree
  add_index "image_uploads", ["theme_id"], name: "index_image_uploads_on_theme_id", unique: true, using: :btree
  add_index "image_uploads", ["version"], name: "index_image_uploads_on_version", using: :btree

  create_table "improve_suggestions", force: :cascade do |t|
    t.integer  "site_id",    limit: 4
    t.string   "name",       limit: 255
    t.text     "data",       limit: 65535
    t.datetime "updated_at"
  end

  add_index "improve_suggestions", ["site_id", "name", "updated_at"], name: "index_improve_suggestions_on_site_id_and_name_and_updated_at", using: :btree

  create_table "internal_processing", id: false, force: :cascade do |t|
    t.integer "last_updated_at",                limit: 4, null: false
    t.integer "last_event_processed",           limit: 4, null: false
    t.integer "last_prop_processed",            limit: 4, null: false
    t.integer "last_visitor_user_id_processed", limit: 4, null: false
  end

  create_table "payment_method_details", force: :cascade do |t|
    t.integer  "payment_method_id", limit: 4
    t.string   "type",              limit: 255
    t.text     "data",              limit: 65535
    t.datetime "created_at"
  end

  add_index "payment_method_details", ["payment_method_id"], name: "index_payment_method_details_on_payment_method_id", using: :btree

  create_table "payment_methods", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "payment_methods", ["deleted_at"], name: "index_payment_methods_on_deleted_at", using: :btree
  add_index "payment_methods", ["user_id"], name: "index_payment_methods_on_user_id", using: :btree

  create_table "referral_tokens", force: :cascade do |t|
    t.string   "token",            limit: 255
    t.integer  "tokenizable_id",   limit: 4
    t.string   "tokenizable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "referrals", force: :cascade do |t|
    t.integer  "sender_id",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                    limit: 255
    t.text     "body",                     limit: 65535
    t.integer  "recipient_id",             limit: 4
    t.datetime "redeemed_by_sender_at"
    t.datetime "redeemed_by_recipient_at"
    t.integer  "site_id",                  limit: 4
    t.boolean  "available_to_sender",                    default: false
    t.integer  "state",                    limit: 4,     default: 0
  end

  add_index "referrals", ["sender_id"], name: "index_referrals_on_sender_id", using: :btree

  create_table "rules", force: :cascade do |t|
    t.integer  "site_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.integer  "priority",   limit: 4
    t.string   "match",      limit: 255
    t.boolean  "editable",               default: true
    t.datetime "deleted_at"
  end

  add_index "rules", ["site_id"], name: "index_rules_on_site_id", using: :btree

  create_table "site_elements", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "element_subtype",                  limit: 255,                              null: false
    t.string   "target_segment",                   limit: 255
    t.boolean  "closable",                                          default: false
    t.boolean  "show_border",                                       default: false
    t.string   "background_color",                 limit: 255,      default: "eb593c"
    t.string   "border_color",                     limit: 255,      default: "ffffff"
    t.string   "button_color",                     limit: 255,      default: "000000"
    t.string   "font_id",                          limit: 255,      default: "open_sans"
    t.string   "link_color",                       limit: 255,      default: "ffffff"
    t.string   "link_style",                       limit: 255,      default: "button"
    t.string   "link_text",                        limit: 5000,     default: "Click Here"
    t.text     "headline",                         limit: 16777215
    t.string   "size",                             limit: 255,      default: "large"
    t.string   "target",                           limit: 255
    t.string   "text_color",                       limit: 255,      default: "ffffff"
    t.string   "texture",                          limit: 255,      default: "none"
    t.boolean  "paused",                                            default: false
    t.integer  "rule_id",                          limit: 4
    t.text     "settings",                         limit: 65535
    t.boolean  "show_branding",                                     default: true
    t.integer  "contact_list_id",                  limit: 4
    t.string   "display_when",                     limit: 255,      default: "immediately"
    t.string   "thank_you_text",                   limit: 255
    t.boolean  "pushes_page_down",                                  default: true
    t.boolean  "remains_at_top",                                    default: true
    t.integer  "wordpress_bar_id",                 limit: 4
    t.boolean  "open_in_new_window",                                default: false
    t.boolean  "animated",                                          default: true
    t.boolean  "wiggle_button",                                     default: false
    t.string   "type",                             limit: 255,      default: "Bar"
    t.text     "caption",                          limit: 16777215
    t.string   "placement",                        limit: 255
    t.datetime "deleted_at"
    t.string   "view_condition",                   limit: 255,      default: "immediately"
    t.string   "email_placeholder",                limit: 255,      default: "Your email",  null: false
    t.string   "name_placeholder",                 limit: 255,      default: "Your name",   null: false
    t.integer  "image_upload_id",                  limit: 4
    t.string   "image_placement",                  limit: 255,      default: "bottom"
    t.integer  "active_image_id",                  limit: 4
    t.string   "question",                         limit: 255
    t.string   "answer1",                          limit: 255
    t.string   "answer2",                          limit: 255
    t.string   "answer1response",                  limit: 255
    t.string   "answer2response",                  limit: 255
    t.string   "answer1link_text",                 limit: 255
    t.string   "answer2link_text",                 limit: 255
    t.string   "answer1caption",                   limit: 255
    t.string   "answer2caption",                   limit: 255
    t.boolean  "use_question",                                      default: false
    t.string   "phone_number",                     limit: 255
    t.string   "phone_country_code",               limit: 255,      default: "US"
    t.string   "theme_id",                         limit: 255
    t.boolean  "use_default_image",                                 default: true,          null: false
    t.text     "blocks",                           limit: 65535
    t.text     "custom_html",                      limit: 65535
    t.text     "custom_css",                       limit: 65535
    t.text     "custom_js",                        limit: 65535
    t.string   "offer_headline",                   limit: 255
    t.string   "offer_text",                       limit: 255
    t.string   "disclaimer",                       limit: 255
    t.text     "content",                          limit: 65535
    t.string   "sound",                            limit: 255,      default: "none",        null: false
    t.integer  "notification_delay",               limit: 4,        default: 10,            null: false
    t.string   "trigger_color",                    limit: 255,      default: "31b5ff",      null: false
    t.string   "trigger_icon_color",               limit: 255,      default: "ffffff",      null: false
    t.string   "content_upgrade_pdf_file_name",    limit: 255
    t.string   "content_upgrade_pdf_content_type", limit: 255
    t.integer  "content_upgrade_pdf_file_size",    limit: 4
    t.datetime "content_upgrade_pdf_updated_at"
    t.string   "content_upgrade_title",            limit: 255
    t.text     "content_upgrade_url",              limit: 65535
    t.boolean  "thank_you_enabled",                                 default: false
    t.string   "thank_you_headline",               limit: 255
    t.string   "thank_you_subheading",             limit: 255
    t.string   "thank_you_cta",                    limit: 255
    t.text     "thank_you_url",                    limit: 65535
  end

  add_index "site_elements", ["contact_list_id"], name: "index_site_elements_on_contact_list_id", using: :btree
  add_index "site_elements", ["element_subtype"], name: "index_site_elements_on_element_subtype", using: :btree
  add_index "site_elements", ["image_upload_id"], name: "index_site_elements_on_image_upload_id", using: :btree
  add_index "site_elements", ["rule_id"], name: "index_site_elements_on_rule_id", using: :btree

  create_table "site_memberships", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "site_id",    limit: 4
    t.string   "role",       limit: 255, default: "owner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "site_memberships", ["site_id"], name: "index_site_memberships_on_site_id", using: :btree
  add_index "site_memberships", ["user_id"], name: "index_site_memberships_on_user_id", using: :btree

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",                             limit: 255
    t.boolean  "opted_in_to_email_digest",                      default: true
    t.datetime "script_installed_at"
    t.datetime "script_generated_at"
    t.datetime "script_attempted_to_generate_at"
    t.string   "read_key",                        limit: 255
    t.string   "write_key",                       limit: 255
    t.string   "timezone",                        limit: 255
    t.datetime "deleted_at"
    t.datetime "script_uninstalled_at"
    t.string   "install_type",                    limit: 255
    t.text     "invoice_information",             limit: 65535
    t.datetime "selected_goal_clicked_at"
    t.text     "settings",                        limit: 65535
  end

  add_index "sites", ["created_at"], name: "index_sites_on_created_at", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.integer  "site_id",              limit: 4
    t.string   "type",                 limit: 255
    t.integer  "schedule",             limit: 4,                           default: 0
    t.decimal  "amount",                           precision: 7, scale: 2
    t.integer  "visit_overage",        limit: 4
    t.integer  "visit_overage_unit",   limit: 4
    t.decimal  "visit_overage_amount",             precision: 5, scale: 2
    t.datetime "created_at"
    t.integer  "payment_method_id",    limit: 4
  end

  add_index "subscriptions", ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
  add_index "subscriptions", ["payment_method_id"], name: "index_subscriptions_on_payment_method_id", using: :btree
  add_index "subscriptions", ["site_id"], name: "index_subscriptions_on_site_id", using: :btree

  create_table "user_onboarding_statuses", force: :cascade do |t|
    t.integer  "user_id",                 limit: 4
    t.integer  "status_id",               limit: 4
    t.integer  "sequence_delivered_last", limit: 4
    t.datetime "created_at"
  end

  add_index "user_onboarding_statuses", ["user_id"], name: "index_user_onboarding_statuses_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                               limit: 255, default: "",       null: false
    t.string   "encrypted_password",                  limit: 255, default: "",       null: false
    t.string   "reset_password_token",                limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       limit: 4,   default: 0,        null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",                  limit: 255
    t.string   "last_sign_in_ip",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",                          limit: 255
    t.string   "last_name",                           limit: 255
    t.string   "status",                              limit: 255, default: "active"
    t.datetime "deleted_at"
    t.string   "invite_token",                        limit: 255
    t.datetime "invite_token_expire_at"
    t.integer  "wordpress_user_id",                   limit: 4
    t.datetime "exit_intent_modal_last_shown_at"
    t.datetime "upgrade_suggest_modal_last_shown_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
