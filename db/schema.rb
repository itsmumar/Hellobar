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

ActiveRecord::Schema.define(version: 20181010212551) do

  create_table "admin_login_attempts", force: :cascade do |t|
    t.string   "email",         limit: 255
    t.string   "ip_address",    limit: 255
    t.string   "user_agent",    limit: 255
    t.string   "access_cookie", limit: 255
    t.datetime "attempted_at"
  end

  create_table "admins", force: :cascade do |t|
    t.string   "email",               limit: 191
    t.string   "initial_password",    limit: 255
    t.string   "password_hashed",     limit: 255
    t.string   "session_token",       limit: 191
    t.string   "permissions_json",    limit: 255
    t.datetime "session_last_active"
    t.integer  "login_attempts",      limit: 4,   default: 0
    t.boolean  "locked",                          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_token",           limit: 191
    t.string   "authentication_code", limit: 255
    t.string   "rotp_secret_base",    limit: 255
  end

  add_index "admins", ["api_token"], name: "index_admins_on_api_token", using: :btree
  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["session_token"], name: "index_admins_on_session_token", using: :btree

  create_table "affiliate_commissions", force: :cascade do |t|
    t.integer "identifier", limit: 4, null: false
    t.integer "bill_id",    limit: 4, null: false
  end

  add_index "affiliate_commissions", ["identifier", "bill_id"], name: "index_affiliate_commissions_on_identifier_and_bill_id", using: :btree

  create_table "affiliate_information", force: :cascade do |t|
    t.integer  "user_id",               limit: 4,   null: false
    t.string   "visitor_identifier",    limit: 255, null: false
    t.string   "affiliate_identifier",  limit: 255, null: false
    t.string   "conversion_identifier", limit: 255
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "affiliate_information", ["user_id"], name: "index_affiliate_information_on_user_id", using: :btree

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "provider",      limit: 255, null: false
    t.string   "uid",           limit: 191
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
    t.integer  "bill_id",        limit: 4
    t.string   "response",       limit: 255
    t.datetime "created_at"
    t.integer  "credit_card_id", limit: 4
    t.string   "status",         limit: 255, default: "pending", null: false
    t.string   "action",         limit: 255, default: "charge"
  end

  add_index "billing_attempts", ["bill_id"], name: "index_billing_attempts_on_bill_id", using: :btree
  add_index "billing_attempts", ["credit_card_id"], name: "index_billing_attempts_on_credit_card_id", using: :btree

  create_table "bills", force: :cascade do |t|
    t.integer  "subscription_id",      limit: 4
    t.decimal  "amount",                           precision: 7,  scale: 2
    t.string   "description",          limit: 255
    t.boolean  "grace_period_allowed",                                      default: true
    t.datetime "bill_at"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "status_set_at"
    t.datetime "created_at"
    t.decimal  "discount",                         precision: 10,           default: 0
    t.decimal  "base_amount",                      precision: 10
    t.string   "authorization_code",   limit: 255
    t.string   "status",               limit: 20,                           default: "pending", null: false
  end

  add_index "bills", ["bill_at"], name: "index_bills_on_type_and_bill_at", using: :btree
  add_index "bills", ["status", "bill_at"], name: "index_bills_on_status_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "bill_at"], name: "index_bills_on_subscription_id_and_type_and_bill_at", using: :btree
  add_index "bills", ["subscription_id", "status", "bill_at"], name: "index_bills_on_subscription_id_and_status_and_bill_at", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.integer  "contact_list_id", limit: 4,                     null: false
    t.string   "name",            limit: 255,                   null: false
    t.string   "status",          limit: 20,  default: "draft", null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "sent_at"
    t.datetime "archived_at"
    t.integer  "email_id",        limit: 4
  end

  add_index "campaigns", ["deleted_at"], name: "index_campaigns_on_deleted_at", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.integer  "rule_id",    limit: 4
    t.string   "segment",    limit: 255,      null: false
    t.string   "operand",    limit: 255,      null: false
    t.text     "value",      limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "conditions", ["rule_id"], name: "index_conditions_on_rule_id", using: :btree

  create_table "contact_lists", force: :cascade do |t|
    t.integer  "site_id",      limit: 4
    t.integer  "identity_id",  limit: 4
    t.string   "name",         limit: 255
    t.text     "data",         limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "double_optin",                  default: true
    t.datetime "deleted_at"
  end

  add_index "contact_lists", ["identity_id"], name: "index_contact_lists_on_identity_id", using: :btree
  add_index "contact_lists", ["site_id"], name: "index_contact_lists_on_site_id", using: :btree

  create_table "content_upgrade_settings", force: :cascade do |t|
    t.integer  "content_upgrade_id",               limit: 4
    t.string   "offer_headline",                   limit: 255
    t.string   "disclaimer",                       limit: 255
    t.string   "content_upgrade_pdf_file_name",    limit: 255
    t.string   "content_upgrade_pdf_content_type", limit: 255
    t.integer  "content_upgrade_pdf_file_size",    limit: 4
    t.datetime "content_upgrade_pdf_updated_at"
    t.string   "content_upgrade_title",            limit: 255
    t.text     "content_upgrade_url",              limit: 65535
    t.boolean  "thank_you_enabled"
    t.string   "thank_you_headline",               limit: 255
    t.string   "thank_you_subheading",             limit: 255
    t.string   "thank_you_cta",                    limit: 255
    t.text     "thank_you_url",                    limit: 65535
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  add_index "content_upgrade_settings", ["content_upgrade_id"], name: "index_content_upgrade_settings_on_content_upgrade_id", using: :btree

  create_table "content_upgrade_styles", force: :cascade do |t|
    t.integer  "site_id",                limit: 4
    t.string   "offer_bg_color",         limit: 255
    t.string   "offer_text_color",       limit: 255
    t.string   "offer_link_color",       limit: 255
    t.string   "offer_border_color",     limit: 255
    t.string   "offer_border_width",     limit: 255
    t.string   "offer_border_style",     limit: 255
    t.string   "offer_border_radius",    limit: 255
    t.string   "modal_button_color",     limit: 255
    t.string   "offer_font_size",        limit: 255
    t.string   "offer_font_weight",      limit: 255
    t.string   "offer_font_family_name", limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "content_upgrade_styles", ["site_id"], name: "index_content_upgrade_styles_on_site_id", using: :btree

  create_table "coupon_uses", force: :cascade do |t|
    t.integer  "coupon_id",  limit: 4, null: false
    t.integer  "bill_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "coupon_uses", ["bill_id"], name: "fk_rails_73bec6a49d", using: :btree
  add_index "coupon_uses", ["coupon_id"], name: "fk_rails_f2d61c8f47", using: :btree

  create_table "coupons", force: :cascade do |t|
    t.string   "label",      limit: 255,                                         null: false
    t.decimal  "amount",                 precision: 7, scale: 2,                 null: false
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.boolean  "public",                                         default: false, null: false
  end

  create_table "credit_cards", force: :cascade do |t|
    t.string   "number",     limit: 255, null: false
    t.integer  "month",      limit: 4,   null: false
    t.integer  "year",       limit: 4,   null: false
    t.string   "first_name", limit: 255, null: false
    t.string   "last_name",  limit: 255, null: false
    t.string   "brand",      limit: 255, null: false
    t.string   "city",       limit: 255, null: false
    t.string   "state",      limit: 255, null: false
    t.string   "zip",        limit: 255, null: false
    t.string   "address",    limit: 255, null: false
    t.string   "country",    limit: 255, null: false
    t.string   "token",      limit: 255
    t.integer  "user_id",    limit: 4
    t.datetime "deleted_at"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "credit_cards", ["user_id"], name: "index_credit_cards_on_user_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer  "site_id",    limit: 4,     null: false
    t.string   "from_name",  limit: 255,   null: false
    t.string   "from_email", limit: 255,   null: false
    t.string   "subject",    limit: 255,   null: false
    t.text     "body",       limit: 65535, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "identities", force: :cascade do |t|
    t.integer  "site_id",     limit: 4
    t.string   "provider",    limit: 255
    t.text     "credentials", limit: 16777215
    t.text     "extra",       limit: 16777215
    t.text     "embed_code",  limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key",     limit: 255
  end

  create_table "image_uploads", force: :cascade do |t|
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",            limit: 4
  end

  add_index "image_uploads", ["site_id"], name: "index_image_uploads_on_site_id", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,     null: false
    t.integer  "application_id",    limit: 4,     null: false
    t.string   "token",             limit: 255,   null: false
    t.integer  "expires_in",        limit: 4,     null: false
    t.text     "redirect_uri",      limit: 65535, null: false
    t.datetime "created_at",                      null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["application_id"], name: "fk_rails_b4b53e07b8", using: :btree
  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id",      limit: 4
    t.integer  "application_id",         limit: 4
    t.string   "token",                  limit: 255,              null: false
    t.string   "refresh_token",          limit: 255
    t.integer  "expires_in",             limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                                      null: false
    t.string   "scopes",                 limit: 255
    t.string   "previous_refresh_token", limit: 255, default: "", null: false
  end

  add_index "oauth_access_tokens", ["application_id"], name: "fk_rails_732cb83ab7", using: :btree
  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 255,                null: false
    t.string   "uid",          limit: 255,                null: false
    t.string   "secret",       limit: 255,                null: false
    t.text     "redirect_uri", limit: 65535,              null: false
    t.string   "scopes",       limit: 255,   default: "", null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "partners", force: :cascade do |t|
    t.string   "first_name",           limit: 255
    t.string   "last_name",            limit: 255
    t.string   "email",                limit: 255
    t.string   "community",            limit: 255
    t.string   "affiliate_identifier", limit: 255,                 null: false
    t.string   "partner_plan_id",      limit: 255,                 null: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "require_credit_card",              default: false
  end

  add_index "partners", ["affiliate_identifier"], name: "index_partners_on_affiliate_identifier", unique: true, using: :btree

  create_table "referral_tokens", force: :cascade do |t|
    t.string   "token",            limit: 255
    t.integer  "tokenizable_id",   limit: 4
    t.string   "tokenizable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "referral_tokens", ["tokenizable_id", "tokenizable_type"], name: "index_referral_tokens_on_tokenizable_id_and_tokenizable_type", using: :btree

  create_table "referrals", force: :cascade do |t|
    t.integer  "sender_id",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                    limit: 255
    t.text     "body",                     limit: 16777215
    t.integer  "recipient_id",             limit: 4
    t.datetime "redeemed_by_sender_at"
    t.datetime "redeemed_by_recipient_at"
    t.integer  "site_id",                  limit: 4
    t.boolean  "available_to_sender",                       default: false
    t.string   "state",                    limit: 20,       default: "sent", null: false
  end

  add_index "referrals", ["sender_id"], name: "index_referrals_on_sender_id", using: :btree

  create_table "rules", force: :cascade do |t|
    t.integer  "site_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.string   "match",      limit: 255
    t.boolean  "editable",               default: true
    t.datetime "deleted_at"
  end

  add_index "rules", ["site_id"], name: "index_rules_on_site_id", using: :btree

  create_table "sequence_steps", force: :cascade do |t|
    t.integer  "delay",           limit: 4,   default: 0, null: false
    t.integer  "sequence_id",     limit: 4,               null: false
    t.integer  "executable_id",   limit: 4,               null: false
    t.string   "executable_type", limit: 255,             null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",            limit: 255
  end

  add_index "sequence_steps", ["executable_type", "executable_id"], name: "index_sequence_steps_on_executable_type_and_executable_id", using: :btree
  add_index "sequence_steps", ["sequence_id"], name: "index_sequence_steps_on_sequence_id", using: :btree

  create_table "sequences", force: :cascade do |t|
    t.string   "name",            limit: 255, null: false
    t.integer  "contact_list_id", limit: 4,   null: false
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sequences", ["contact_list_id"], name: "index_sequences_on_contact_list_id", using: :btree

  create_table "site_elements", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "element_subtype",               limit: 191,                             null: false
    t.boolean  "closable",                                       default: false
    t.boolean  "show_border",                                    default: false
    t.string   "background_color",              limit: 255,      default: "eb593c"
    t.string   "border_color",                  limit: 255,      default: "ffffff"
    t.string   "button_color",                  limit: 255,      default: "000000"
    t.string   "font_id",                       limit: 255,      default: "open_sans"
    t.string   "link_color",                    limit: 255,      default: "ffffff"
    t.string   "link_text",                     limit: 5000,     default: "Click Here"
    t.text     "headline",                      limit: 16777215
    t.string   "size",                          limit: 255,      default: "large"
    t.string   "text_color",                    limit: 255,      default: "ffffff"
    t.string   "texture",                       limit: 255,      default: "none"
    t.integer  "rule_id",                       limit: 4
    t.text     "settings",                      limit: 16777215
    t.boolean  "show_branding",                                  default: true
    t.integer  "contact_list_id",               limit: 4
    t.string   "thank_you_text",                limit: 255
    t.boolean  "pushes_page_down",                               default: true
    t.boolean  "remains_at_top",                                 default: true
    t.integer  "wordpress_bar_id",              limit: 4
    t.boolean  "open_in_new_window",                             default: false
    t.boolean  "animated",                                       default: true
    t.boolean  "wiggle_button",                                  default: false
    t.string   "type",                          limit: 255
    t.text     "caption",                       limit: 16777215
    t.text     "content",                       limit: 16777215
    t.string   "placement",                     limit: 255
    t.datetime "deleted_at"
    t.string   "view_condition",                limit: 255,      default: "wait-5"
    t.string   "email_placeholder",             limit: 255,      default: "Your email", null: false
    t.string   "name_placeholder",              limit: 255,      default: "Your name",  null: false
    t.string   "image_placement",               limit: 255,      default: "bottom"
    t.integer  "active_image_id",               limit: 4
    t.string   "question",                      limit: 255
    t.string   "answer1",                       limit: 255
    t.string   "answer2",                       limit: 255
    t.string   "answer1response",               limit: 255
    t.string   "answer2response",               limit: 255
    t.string   "answer1link_text",              limit: 255
    t.string   "answer2link_text",              limit: 255
    t.string   "answer1caption",                limit: 255
    t.string   "answer2caption",                limit: 255
    t.boolean  "use_question",                                   default: false
    t.string   "phone_number",                  limit: 255
    t.string   "phone_country_code",            limit: 255,      default: "US"
    t.string   "theme_id",                      limit: 255
    t.boolean  "use_default_image",                              default: true,         null: false
    t.string   "offer_text",                    limit: 255
    t.string   "sound",                         limit: 255,      default: "none",       null: false
    t.integer  "notification_delay",            limit: 4,        default: 10,           null: false
    t.string   "trigger_color",                 limit: 255,      default: "31b5ff",     null: false
    t.string   "trigger_icon_color",            limit: 255,      default: "ffffff",     null: false
    t.integer  "image_opacity",                 limit: 4,        default: 100
    t.boolean  "enable_gdpr",                                    default: false
    t.datetime "paused_at"
    t.string   "image_overlay_color",           limit: 10,       default: "ffffff"
    t.integer  "image_overlay_opacity",         limit: 1,        default: 0
    t.string   "text_field_border_color",       limit: 10,       default: "e0e0e0"
    t.integer  "text_field_border_width",       limit: 1,        default: 1
    t.integer  "text_field_border_radius",      limit: 1,        default: 2
    t.string   "text_field_text_color",         limit: 10,       default: "5c5e60"
    t.string   "text_field_background_color",   limit: 10,       default: "ffffff"
    t.integer  "text_field_background_opacity", limit: 1,        default: 100
    t.string   "cta_border_color",              limit: 255,      default: "ffffff",     null: false
    t.integer  "cta_border_width",              limit: 4,        default: 0,            null: false
    t.integer  "cta_border_radius",             limit: 4,        default: 0,            null: false
    t.integer  "cta_height",                    limit: 4,        default: 27,           null: false
    t.string   "conversion_font",               limit: 255,      default: "Roboto",     null: false
    t.string   "conversion_font_color",         limit: 255,      default: "ffffff",     null: false
    t.integer  "conversion_font_size",          limit: 4,        default: 12,           null: false
    t.datetime "deactivated_at"
    t.string   "text_field_font_family",        limit: 255
    t.integer  "text_field_font_size",          limit: 4,        default: 14
    t.boolean  "show_optional_caption",                          default: true,         null: false
    t.boolean  "show_optional_content",                          default: true,         null: false
  end

  add_index "site_elements", ["contact_list_id"], name: "index_site_elements_on_contact_list_id", using: :btree
  add_index "site_elements", ["element_subtype"], name: "index_site_elements_on_element_subtype", using: :btree
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
    t.boolean  "opted_in_to_email_digest",                         default: true
    t.datetime "script_installed_at"
    t.datetime "script_generated_at"
    t.datetime "script_attempted_to_generate_at"
    t.string   "read_key",                        limit: 255
    t.string   "write_key",                       limit: 255
    t.string   "timezone",                        limit: 255
    t.datetime "deleted_at"
    t.datetime "script_uninstalled_at"
    t.string   "install_type",                    limit: 255
    t.text     "invoice_information",             limit: 16777215
    t.string   "privacy_policy_url",              limit: 255
    t.string   "terms_and_conditions_url",        limit: 255
    t.string   "communication_types",             limit: 255,      default: "newsletter,promotional,partnership,product,research"
    t.string   "gdpr_consent_language",           limit: 10,       default: "en"
    t.boolean  "warning_email_one_sent",                           default: false
    t.boolean  "warning_email_two_sent",                           default: false
    t.boolean  "warning_email_three_sent",                         default: false
    t.boolean  "limit_email_sent",                                 default: false
    t.boolean  "upsell_email_sent",                                default: false
    t.integer  "overage_count",                   limit: 4,        default: 0
    t.boolean  "ab_test_running",                                  default: false
    t.string   "pre_selected_plan",               limit: 255
    t.datetime "auto_upgraded_at"
  end

  add_index "sites", ["created_at"], name: "index_sites_on_created_at", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "site_id",              limit: 4
    t.string   "type",                 limit: 255
    t.decimal  "amount",                           precision: 7, scale: 2
    t.integer  "visit_overage",        limit: 4
    t.integer  "visit_overage_unit",   limit: 4
    t.decimal  "visit_overage_amount",             precision: 5, scale: 2
    t.datetime "created_at"
    t.datetime "trial_end_date"
    t.integer  "credit_card_id",       limit: 4
    t.string   "schedule",             limit: 20,                          default: "monthly", null: false
    t.datetime "deleted_at"
    t.datetime "updated_at"
    t.decimal  "original_amount",                  precision: 7, scale: 2
  end

  add_index "subscriptions", ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
  add_index "subscriptions", ["credit_card_id"], name: "index_subscriptions_on_credit_card_id", using: :btree
  add_index "subscriptions", ["site_id"], name: "index_subscriptions_on_site_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                               limit: 191, default: "",       null: false
    t.string   "encrypted_password",                  limit: 255, default: "",       null: false
    t.string   "reset_password_token",                limit: 191
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

  create_table "whitelabels", force: :cascade do |t|
    t.string   "domain",            limit: 255,                 null: false
    t.string   "subdomain",         limit: 255,                 null: false
    t.string   "status",            limit: 20,  default: "new", null: false
    t.integer  "site_id",           limit: 4,                   null: false
    t.integer  "domain_identifier", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "coupon_uses", "bills"
  add_foreign_key "coupon_uses", "coupons"
  add_foreign_key "credit_cards", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "subscriptions", "credit_cards"
end
