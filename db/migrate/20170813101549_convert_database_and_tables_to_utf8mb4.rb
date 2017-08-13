class ConvertDatabaseAndTablesToUtf8mb4 < ActiveRecord::Migration
  def up
    # There is one important thing you should know - when switching to utf8mb4
    # charset, the maximum length of a column or index key is the same as in
    # utf8 charset in terms of bytes. This means it is smaller in terms of
    # characters, since the maximum length of a character in utf8mb4 is four
    # bytes, instead of three in utf8. The maximum index length of InnoDB
    # storage engine is 767 bytes, so if you are indexing your VARCHAR columns,
    # you would need to change their length to 191 instead of 255.
    # http://blog.arkency.com/2015/05/how-to-store-emoji-in-a-rails-app-with-a-mysql-database/

    # change to VARCHAR(191)
    execute 'ALTER TABLE admins CHANGE api_token api_token VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE admins CHANGE email email VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE admins CHANGE session_token session_token VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE authentications CHANGE uid uid VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE bills CHANGE type type VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE image_uploads CHANGE theme_id theme_id VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE improve_suggestions CHANGE name name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE site_elements CHANGE element_subtype element_subtype VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;'

    execute 'ALTER TABLE schema_migrations CHANGE version version VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    execute 'ALTER TABLE users CHANGE email email VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT "" NOT NULL;'
    execute 'ALTER TABLE users CHANGE reset_password_token reset_password_token VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    # change some weird stuff about text columns
    execute 'ALTER TABLE site_elements CHANGE headline headline MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE site_elements CHANGE caption caption MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'

    # change to utf8mb4
    execute 'ALTER TABLE admin_login_attempts     CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE admins                   CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE authentications          CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE autofills                CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE billing_attempts         CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE bills                    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE conditions               CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE contact_list_logs        CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE contact_lists            CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE coupon_uses              CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE coupons                  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE credit_cards             CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE identities               CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE image_uploads            CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE improve_suggestions      CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE internal_processing      CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE payment_method_details   CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE payment_methods          CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE referral_tokens          CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE referrals                CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE rules                    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE schema_migrations        CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE site_elements            CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE site_memberships         CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE sites                    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE subscriptions            CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE user_onboarding_statuses CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
    execute 'ALTER TABLE users                    CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
  end
end
