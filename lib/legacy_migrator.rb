require_relative './legacy_migrator/legacy_model'
require_relative './legacy_migrator/date_time_converter'

class LegacyMigrator
  extend DateTimeConverter

  class << self
    def migrate
      ActiveRecord::Base.record_timestamps = false

      migrate_sites_and_users_and_memberships
      migrate_identities
      migrate_contact_lists
      migrate_goals_to_rules

      ActiveRecord::Base.record_timestamps = true
    end

    def migrate_sites_and_users_and_memberships
      count = 0
      LegacySite.find_each do |legacy_site|
        begin
        site = ::Site.create! id: legacy_site.legacy_site_id || legacy_site.id,
                              url: legacy_site.base_url,
                              script_installed_at: legacy_site.script_installed_at,
                              script_generated_at: legacy_site.generated_script,
                              script_attempted_to_generate_at: legacy_site.attempted_generate_script,
                              created_at: legacy_site.created_at.utc,
                              updated_at: legacy_site.updated_at.utc

        create_user_and_membership legacy_site_id: site.id,
                                   account_id: legacy_site.account_id

        count += 1
        puts "Migrated #{count} sites" if count % 100 == 0
        rescue ActiveRecord::RecordInvalid => e
          raise e.inspect
        end
      end
    end

    def migrate_goals_to_rules
      count = 0

      sites_needing_rules = []

      ::Site.find_each do |site|
        legacy_goals = LegacyGoal.where(site_id: site.id)

        if legacy_goals.present?
          legacy_goals.each do |legacy_goal|
            rule = ::Rule.create! id: legacy_goal.id,
                                  site_id: legacy_goal.site_id,
                                  name: 'Everyone', # or /URL? TODO
                                  priority: legacy_goal.priority,
                                  match: Rule::MATCH_ON[:all],
                                  created_at: legacy_goal.created_at.utc,
                                  updated_at: legacy_goal.updated_at.utc

            create_conditions(rule, legacy_goal).each do |new_condition|
              rule.conditions << new_condition
            end

            create_site_elements(legacy_goal.bars, legacy_goal).each do |new_bar|
              rule.site_elements << new_bar
            end

            count += 1
            puts "Migrated #{count} goals to rules" if count % 100 == 0
          end
        else # site has no rules so add them to the collection
          sites_needing_rules << site
        end
      end

      # lets avoid ID collisions with legacy goals
      sites_needing_rules.each{|site| site.create_default_rule }
    end

    def migrate_contact_lists
      count = 0

      LegacyGoal.find_each do |legacy_goal|
        next unless legacy_goal.type == "Goals::CollectEmail"

        unless Site.exists?(legacy_goal.site_id)
          Rails.logger.info "WTF:Legacy Site: #{legacy_goal.site_id} doesnt exist for Goal: #{legacy_goal.id}"
          next
        end

        params = {
          id: legacy_goal.id,
          site_id: legacy_goal.site_id,
          name: "List #{legacy_goal.id}",
          created_at: legacy_goal.created_at.utc,
          updated_at: legacy_goal.updated_at.utc
        }

        if legacy_id_int = LegacyIdentityIntegration.where(:integrable_id => legacy_goal.id).first
          unless Identity.exists?(legacy_id_int.identity_id)
            Rails.logger.info "WTF:Identity: #{legacy_id_int.identity_id} doesnt exist for Goal: #{legacy_goal.id}"
            next
          end

          identity = legacy_id_int.identity

          params.merge!(
            identity_id: legacy_id_int.identity_id,
            data: legacy_id_int.data.merge(embed_code: identity.embed_code),
            name: legacy_id_int.data["remote_name"],
            last_synced_at: legacy_id_int.last_synced_at,
            created_at: legacy_id_int.created_at,
            updated_at: legacy_id_int.updated_at
          )
        end

        ::ContactList.create!(params)

        count += 1
        puts "Migrated #{count} contact lists" if count % 100 == 0
      end
    end

    def migrate_identities
      count = 0
      LegacyIdentity.find_each do |legacy_id|
        if ::Site.exists?(legacy_id.site_id)
          ::Identity.create! id: legacy_id.id,
                             site_id: legacy_id.site_id,
                             provider: legacy_id.provider,
                             credentials: legacy_id.credentials,
                             extra: legacy_id.extra,
                             created_at: legacy_id.created_at,
                             updated_at: legacy_id.updated_at

          count += 1
          puts "Migrated #{count} identities" if count % 100 == 0
        else
          Rails.logger.info "WTF:Legacy Site: #{legacy_id.site_id} doesnt exist for Identity: #{legacy_id.id}"
        end
      end
    end

  private

    def create_user_and_membership(legacy_site_id: legacy_site_id, account_id: account_id)
      legacy_account = LegacyAccount.find(account_id)
      legacy_memberships = legacy_account.memberships

      if legacy_memberships.size != 1
        Rails.logger.info "WTF:Legacy Membership has #{legacy_memberships.size} memberships for Account:#{account_id}" if legacy_memberships.size != 1
      else
        legacy_membership = legacy_memberships.first
        legacy_user = legacy_membership.user

        if legacy_user && !::User.exists?(legacy_user.id_to_migrate) && !::Hello::WordpressUser.email_exists?(legacy_user.email)
          begin
            user = ::User.create! id: legacy_user.id_to_migrate,
                                  email: legacy_user.email,
                                  encrypted_password: legacy_user.encrypted_password,
                                  reset_password_token: legacy_user.reset_password_token,
                                  reset_password_sent_at: legacy_user.reset_password_sent_at,
                                  remember_created_at: legacy_user.remember_created_at,
                                  sign_in_count: legacy_user.sign_in_count,
                                  status: ::User::ACTIVE_STATUS,
                                  legacy_migration: true,
                                  current_sign_in_at: legacy_user.current_sign_in_at,
                                  last_sign_in_at: legacy_user.last_sign_in_at,
                                  current_sign_in_ip: legacy_user.current_sign_in_ip,
                                  last_sign_in_ip: legacy_user.last_sign_in_ip,
                                  created_at: legacy_user.original_created_at || legacy_user.created_at,
                                  updated_at: legacy_user.updated_at

          ::SiteMembership.create! user_id: user.id,
                                   site_id: legacy_site_id

          rescue ActiveRecord::RecordNotUnique => e
            Rails.logger.info "WTF:Error creating New user:#{e}"
          end
        else
          Rails.logger.info "WTF:No user found for Legacy Membership id:#{legacy_membership.id}"
        end
      end
    end

    def create_conditions(rule, legacy_goal)
      new_conditions = []

      start_date = convert_start_time(legacy_goal.data_json['start_date'], legacy_goal.data_json['dates_timezone'])
      end_date = convert_end_time(legacy_goal.data_json['end_date'], legacy_goal.data_json['dates_timezone'])
      include_urls = legacy_goal.data_json['include_urls']
      exclude_urls = legacy_goal.data_json['exclude_urls']

      date_condition = DateCondition.from_params(start_date, end_date)
      new_conditions << date_condition if date_condition

      if include_urls.present?
        include_urls.each do |include_url|
          new_conditions << UrlCondition.include_url(include_url)
        end
      end

      if exclude_urls.present?
        exclude_urls.each do |exclude_url|
          new_conditions << UrlCondition.exclude_url(exclude_url)
        end
      end

      new_conditions
    end

    def create_site_elements(legacy_bars, legacy_goal)
      legacy_bars.map do |legacy_bar|
        setting_keys = ["buffer_message", "buffer_url", "collect_names", "link_url", "message_to_tweet", "pinterest_description", "pinterest_full_name", "pinterest_image_url", "pinterest_url", "pinterest_user_url", "twitter_handle", "url", "url_to_like", "url_to_plus_one", "url_to_share", "url_to_tweet", "use_location_for_url"]
        settings_to_migrate = legacy_goal.data_json.select{|key, value| setting_keys.include?(key) && value.present? }

        ::SiteElement.create! id: legacy_bar.legacy_bar_id || legacy_bar.id,
                      paused: !legacy_bar.active?,
                      element_subtype: determine_element_subtype(legacy_goal),
                      created_at: legacy_bar.created_at.utc,
                      updated_at: legacy_bar.updated_at.utc,
                      target_segment: legacy_bar.target_segment,
                      rule_id: legacy_bar.goal_id,
                      closable: legacy_bar.settings_json['closable'],
                      show_border: legacy_bar.settings_json['show_border'],
                      background_color: legacy_bar.settings_json['bar_color'],
                      border_color: legacy_bar.settings_json['border_color'],
                      button_color: legacy_bar.settings_json['button_color'],
                      font: legacy_bar.settings_json['font'],
                      link_color: legacy_bar.settings_json['link_color'],
                      link_style: legacy_bar.settings_json['link_style'],
                      link_text: legacy_bar.settings_json['link_text'],
                      message: legacy_bar.settings_json['message'],
                      size: legacy_bar.settings_json['size'],
                      target: legacy_bar.settings_json['target'],
                      text_color: legacy_bar.settings_json['text_color'],
                      texture: legacy_bar.settings_json['texture'],
                      settings: settings_to_migrate,
                      contact_list: ContactList.where(id: legacy_goal.id).first
      end
    end

    def determine_element_subtype(legacy_goal)
      case legacy_goal.type
      when "Goals::DirectTraffic"
        "traffic"
      when "Goals::CollectEmail"
        "email"
      when "Goals::SocialMedia"
        "social/#{legacy_goal.data_json["interaction"]}"
      end
    end
  end
end
