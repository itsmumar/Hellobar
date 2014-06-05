require_relative './legacy_migrator/legacy_model'
require_relative './legacy_migrator/date_time_helper'

class LegacyMigrator
  extend DateTimeConverter

  class << self
    def migrate
      ActiveRecord::Base.record_timestamps = false

      migrate_sites_and_users_and_memberships
      migrate_goals_to_rule_sets

      ActiveRecord::Base.record_timestamps = true
    end

    def migrate_sites_and_users_and_memberships
      LegacySite.find_each do |legacy_site|
        site = Site.create! id: legacy_site.legacy_site_id || legacy_site.id,
                            url: legacy_site.base_url,
                            created_at: legacy_site.created_at,
                            updated_at: legacy_site.updated_at

        create_user_and_membership legacy_site_id: site.id,
                                   account_id: legacy_site.account_id
      end
    end

    def migrate_goals_to_rule_sets
    # - What to do with :name and :type?
    # - NOT CURRENTLY IMPORTING FROM DATA_JSON:
    #   - ["url", "collect_names", "interaction", "interaction_description", "url_to_tweet", "pinterest_url", "pinterest_image_url", "pinterest_description", "message_to_tweet", "url_to_like", "url_to_share", "twitter_handle", "use_location_for_url", "url_to_plus_one", "pinterest_user_url", "pinterest_full_name", "buffer_message", "buffer_url"]
      LegacyGoal.find_each do |legacy_goal|
        if Site.exist?(legacy_goal.site_id)
          rule_set = RuleSet.create id: legacy_goal.id,
                                    site_id: legacy_goal.site_id,
                                    start_date: convert_start_date(legacy_goal.data_json['start_date'], legacy_goal.data_json['dates_timezone']),
                                    end_date: convert_end_date(legacy_goal.data_json['end_date'], legacy_goal.data_json['dates_timezone']),
                                    include_urls: legacy_goal.data_json['include_urls'],
                                    exclude_urls: legacy_goal.data_json['exclude_urls'],
                                    created_at: legacy_goal.created_at,
                                    updated_at: legacy_goal.updated_at

          create_bars(legacy_goal.bars, legacy_goal.type).each do |new_bar|
            rule_set.bars << new_bar
          end
        else
          Rails.logger.info "WTF: Site ID: #{legacy_goal.site_id} doesnt exist for Goal #{legacy_goal.id}"
        end
      end
    end

  private

    def create_user_and_membership(legacy_site_id: legacy_site_id, account_id: account_id)
      legacy_account = LegacyAccount.find(account_id)
      legacy_memberships = legacy_account.memberships

      if legacy_memberships.size != 1
        Rails.logger.info "WTF: #{legacy_memberships.size} memberships for #{account_id}" if legacy_memberships.size != 1
      else
        legacy_membership = legacy_memberships.first
        legacy_user = legacy_membership.user

        user = User.create! id: legacy_user.legacy_user_id || legacy_user.id,
                            email: legacy_user.email,
                            encrypted_password: legacy_user.encrypted_password,
                            reset_password_token: legacy_user.reset_password_token,
                            reset_password_sent_at: legacy_user.reset_password_sent_at,
                            remember_created_at: legacy_user.remember_created_at,
                            sign_in_count: legacy_user.sign_in_count,
                            current_sign_in_at: legacy_user.current_sign_in_at,
                            last_sign_in_at: legacy_user.last_sign_in_at,
                            current_sign_in_ip: legacy_user.current_sign_in_ip,
                            last_sign_in_ip: legacy_user.last_sign_in_ip,
                            created_at: legacy_user.original_created_at || legacy_user.created_at

        SiteMembership.create! user_id: user.id,
                               site_id: legacy_site_id
      end
    end

    def create_bars(legacy_bars, goal)
      legacy_bars.map do |legacy_bar|
        Bar.create! id: legacy_bar.legacy_bar_id || legacy_bar.id,
                    paused: !legacy_bar.active?,
                    goal: goal,
                    created_at: legacy_bar.created_at,
                    updated_at: legacy_bar.updated_at,
                    target_segment: legacy_bar.target_segment,
                    rule_set_id: legacy_bar.goal_id,
                    closable: legacy_bar.settings_json['closable'],
                    hide_destination: legacy_bar.settings_json['hide_destination'],
                    open_in_new_window: legacy_bar.settings_json['open_in_new_window'],
                    pushes_page_down: legacy_bar.settings_json['pushes_page_down'],
                    remains_at_top: legacy_bar.settings_json['remains_at_top'],
                    show_border: legacy_bar.settings_json['show_border'],
                    hide_after: legacy_bar.settings_json['hide_after'],
                    show_wait: legacy_bar.settings_json['show_wait'],
                    wiggle_wait: legacy_bar.settings_json['wiggle_wait'],
                    bar_color: legacy_bar.settings_json['bar_color'],
                    border_color: legacy_bar.settings_json['border_color'],
                    button_color: legacy_bar.settings_json['button_color'],
                    font: legacy_bar.settings_json['font'],
                    link_color: legacy_bar.settings_json['link_color'],
                    link_style: legacy_bar.settings_json['link_style'],
                    link_text: legacy_bar.settings_json['link_text'],
                    message: legacy_bar.settings_json['message'],
                    size: legacy_bar.settings_json['size'],
                    tab_side: legacy_bar.settings_json['tab_side'],
                    target: legacy_bar.settings_json['target'],
                    text_color: legacy_bar.settings_json['text_color'],
                    texture: legacy_bar.settings_json['texture'],
                    thank_you_text: legacy_bar.settings_json['thank_you_text']
      end
    end
  end
end
