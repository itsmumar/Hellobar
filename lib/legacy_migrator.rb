require_relative './legacy_migrator/legacy_model'

class LegacyMigrator
  class << self
    def migrate
      ActiveRecord::Base.record_timestamps = false

      @migrated_memberships = {}
      puts "[#{Time.now}] Start"
      load_wp_emails
      preload_data
      migrate_sites_and_users_and_memberships
      puts "[#{Time.now}] Done reading, writing..."
      save_to_db(@migrated_memberships)
      save_to_db(@migrated_users)
      save_to_db(@migrated_sites)
      migrate_identities
      migrate_contact_lists
      migrate_goals_to_rules
      migrate_site_timezones
      puts "[#{Time.now}] Done writing, changing subscription..."
      optimize_inserts do
        @migrated_sites.each do |key, site|
          site.change_subscription_no_checks(Subscription::FreePlus.new(schedule: 'monthly'))
        end
      end
      puts "[#{Time.now}] Done"

      ActiveRecord::Base.record_timestamps = true
    end

    def optimize_inserts
      ActiveRecord::Base.connection.execute("SET autocommit=0")
      ActiveRecord::Base.connection.execute("SET unique_checks=0")
      ActiveRecord::Base.connection.execute("SET foreign_key_checks=0")
      yield
      ActiveRecord::Base.connection.execute("SET autocommit=1")
      ActiveRecord::Base.connection.execute("SET unique_checks=1")
      ActiveRecord::Base.connection.execute("SET foreign_key_checks=1")
    end

    def save_to_db(items)
      klass =  items[items.keys.first].class
      count = 0

      ActiveRecord::Base.transaction do
        optimize_inserts do
          items.each do |key, item|
            count += 1
            puts "[#{Time.now}] Saving #{count} #{klass}..." if count % 500 == 0
            item.save(validate: false)
          end
        end
      end
    end
    
    def load_wp_emails
      @wp_emails = {}
      File.read(File.join(Rails.root,"db", "wp_logins.csv")).split("\n").each_with_index do |line, i|
        if i > 0
          e1, e2 = *line.split("\t")
          @wp_emails[e1] = true
          @wp_emails[e2] = true
        end
      end
    end

    def preload(klass, key_method=:id, type=:single)
      puts "[#{Time.now}] Loading #{klass}..."
      if type == :single
        results = {}
        klass.all.each do |object|
          results[object.send(key_method)] = object
        end
      else
        results = Hash.new{|h,k| h[k] = []}
        klass.all.each do |object|
          results[object.send(key_method)] << object
        end
      end
      return results
    end

    def preload_data
      @legacy_sites = preload(LegacyMigrator::LegacySite)
      @legacy_accounts = preload(LegacyMigrator::LegacyAccount)
      @legacy_users = preload(LegacyMigrator::LegacyUser)
      @legacy_memberships = preload(LegacyMigrator::LegacyMembership, :account_id, :collection)
      @migrated_users = {}
      @migrated_sites = {}
    end

    def migrate_sites_and_users_and_memberships
      count = 0
      puts "[#{Time.now}] migrate_sites_and_users_and_memberships.."

      @legacy_sites.each do |id, legacy_site|
        begin
          site = ::Site.new id: legacy_site.legacy_site_id || legacy_site.id,
                                url: legacy_site.base_url,
                                script_installed_at: legacy_site.script_installed_at,
                                script_generated_at: legacy_site.generated_script,
                                script_attempted_to_generate_at: legacy_site.attempted_generate_script,
                                created_at: legacy_site.created_at.utc,
                                updated_at: legacy_site.updated_at.utc

          create_user_and_membership legacy_site_id: site.id,
                                     account_id: legacy_site.account_id


          @migrated_sites[site.id] = site
          count += 1
          puts "Migrated #{count} sites" if count % 1000 == 0
        rescue ActiveRecord::RecordInvalid => e
          raise e.inspect
        end
      end
    end

    def create_rule(id, is_mobile, site, legacy_goal, legacy_bars)
      rule = ::Rule.create! id: id,
                            site_id: site.id,
                            name: 'Everyone', # may be renamed later depending on # of conditions
                            priority: legacy_goal.priority,
                            match: Rule::MATCH_ON[:all],
                            created_at: legacy_goal.created_at.utc,
                            updated_at: legacy_goal.updated_at.utc


      create_conditions(rule, legacy_goal).each do |new_condition|
        rule.conditions << new_condition
      end

      # add the mobile condition if the rule is mobile
      DeviceCondition.create!(operand: 'is', value: 'mobile', rule: rule) if is_mobile

      if existing = existing_rule(rule)
        rule.destroy
        rule = existing
      end

      # create site elements
      create_site_elements(legacy_bars, legacy_goal, rule).each do |new_bar|
        rule.site_elements << new_bar
      end

      rule
    end

    def migrate_goals_to_rules
      goal_count = 0

      sites_needing_rules = []
      mobile_rules_to_create_later = []

      ::Site.find_each do |site|
        legacy_goals = LegacyGoal.where(site_id: site.id)

        if legacy_goals.present?
          legacy_goals.each do |legacy_goal|
            mobile_bars, non_mobile_bars = legacy_goal.bars.partition{|bar| bar_is_mobile?(bar) }

            # create the mobile, non-mobile, or both Rules, conditions, site elements
            if mobile_bars.present? && non_mobile_bars.present?
              # create a non-mobile rule and give it the legacy_goal ID
              create_rule(legacy_goal.id, false, site, legacy_goal, non_mobile_bars)
              # create a mobile rule w/ auto-incrementing ID and add a mobile condition
              mobile_rules_to_create_later << { site: site, legacy_goal: legacy_goal, mobile_bars: mobile_bars }
            elsif mobile_bars.present?
              # create a rule and add the mobile condition
              create_rule(legacy_goal.id, true, site, legacy_goal, mobile_bars)
            else
              # create a rule with the legacy goal ID
              create_rule(legacy_goal.id, false, site, legacy_goal, non_mobile_bars)
            end

            goal_count += 1
            puts "Migrated #{goal_count} goals to rules" if goal_count % 100 == 0
          end
        else # site has no rules so add them to the collection
          sites_needing_rules << site
        end
      end

      # creating mobile rules later to avoid ID collisions
      mobile_rules_to_create_later.each do |data|
        create_rule(nil, true, data[:site], data[:legacy_goal], data[:mobile_bars])
      end

      # rename rules if we need to based on the # of conditions
      ::Site.find_each do |site|
        site.rules.includes(:conditions).each do |rule|
          rule_count = 1
          unless rule.conditions.size.zero?
            rule.update_attribute :name, "Rule #{rule_count}"
            rule_count += 1
          end
        end
      end

      # lets avoid ID collisions with legacy goals
      sites_needing_rules.each{|site| site.create_default_rule }
    end

    # a rule for site which already exists and has same conditions
    def existing_rule(rule)
      rule.site.rules.find { |r| rule.same_as?(r) && rule != r }
    end

    # returns true/false if the bar is targeting mobile users
    def bar_is_mobile?(bar)
      bar.target_segment == 'dv:mobile' ||
        bar.settings_json['target'] == 'dv:mobile'
    end

    def migrate_contact_lists
      count = 0

      @legacy_goals = preload(LegacyMigrator::LegacyGoal)
      @legacy_identity_integrations = preload(LegacyMigrator::LegacyIdentityIntegration, :integrable_id)
      @legacy_goals.each do |id, legacy_goal|
        next unless legacy_goal.type == "Goals::CollectEmail"

        unless @migrated_sites[legacy_goal.site_id]
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

        if legacy_id_int = @legacy_identity_integrations[legacy_goal.id]
          unless identity = @migrated_identities[legacy_id_int.identity_id]
            Rails.logger.info "WTF:Identity: #{legacy_id_int.identity_id} doesnt exist for Goal: #{legacy_goal.id}"
            next
          end

          params.merge!(
            identity_id: legacy_id_int.identity_id,
            data: legacy_id_int.data.merge(embed_code: identity.embed_code),
            name: legacy_id_int.data["remote_name"],
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
      @migrated_identities = {}
      @legacy_identities = preload(LegacyMigrator::LegacyIdentity)
      @legacy_identities.each do |id, legacy_id|
        if site = @legacy_sites[legacy_id.site_id]
          identity = ::Identity.create! id: legacy_id.id,
                             site_id: legacy_id.site_id,
                             provider: legacy_id.provider,
                             credentials: legacy_id.credentials,
                             extra: legacy_id.extra,
                             created_at: legacy_id.created_at,
                             updated_at: legacy_id.updated_at

          count += 1
          @migrated_identities[identity.id] = identity
          puts "Migrated #{count} identities" if count % 100 == 0
        else
          Rails.logger.info "WTF:Legacy Site: #{legacy_id.site_id} doesnt exist for Identity: #{legacy_id.id}"
        end
      end
    end

    def migrate_site_timezones
      LegacySite.find_each do |legacy_site|
        site_id = legacy_site.id

        timezones = LegacyGoal.where(site_id: site_id).map{|goal| timezone_for_goal(goal)}.compact.uniq

        # update the new Site with the first timezone
        if timezones.length >= 1
          ::Site.find(site_id).update_attribute :timezone, timezones.first
        end
      end
    end

    # Returns a timezone if applicable. Returns nil for "visitor" and "false"
    # "(GMT-06:00) Central Time (US & Canada)" => "Central Time (US & Canada)"
    def timezone_for_goal(goal)
      timezone = goal.data_json['dates_timezone'] rescue nil

      return nil if timezone == 'visitor' || timezone == 'false' || timezone.nil?

      timezone[12..-1] # timezone is in a standardized format "(GMT+HH:MM) "
    end

  private

    def create_user_and_membership(legacy_site_id: legacy_site_id, account_id: account_id)
      legacy_account = @legacy_accounts[account_id]
      legacy_memberships = @legacy_memberships[legacy_account.id]

      if legacy_memberships.size != 1
        Rails.logger.info "WTF:Legacy Membership has #{legacy_memberships.size} memberships for Account:#{account_id}" if legacy_memberships.size != 1
      else
        legacy_membership = legacy_memberships.first
        legacy_user = @legacy_users[legacy_membership.user_id]

        unless legacy_user
          Rails.logger.info "WTF:Legacy Membership: #{legacy_membership.id} has no users!"
          return
        end

        # These were already validated presumably on HB 2.0 so need for the following line
        return if @wp_emails[legacy_user.email]

        migrated_user = @migrated_users[legacy_user.id_to_migrate.to_i]
        unless migrated_user
          migrated_user ||= ::User.new id: legacy_user.id_to_migrate,
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

          @migrated_users[legacy_user.id_to_migrate.to_i] = migrated_user
        end
        @migrated_memberships[migrated_user.id.to_s+"-"+legacy_site_id.to_s] = ::SiteMembership.new user_id: migrated_user.id,
                                 site_id: legacy_site_id
      end
    end

    def create_conditions(rule, legacy_goal)
      new_conditions = []

      start_date = legacy_goal.data_json['start_date']
      end_date = legacy_goal.data_json['end_date']
      include_urls = legacy_goal.data_json['include_urls']
      does_not_include_urls = legacy_goal.data_json['exclude_urls'] # legacy key is exclude_urls, which we map to does_not_include

      date_condition = DateCondition.from_params(start_date, end_date)
      new_conditions << date_condition if date_condition

      if include_urls.present?
        include_urls.each do |include_url|
          new_conditions << UrlCondition.new(:operand => :includes,
                                             :value => include_url)
        end
      end

      if does_not_include_urls.present?
        does_not_include_urls.each do |does_not_include_url|
          new_conditions << UrlCondition.new(operand: :does_not_include,
                                             value: does_not_include_url)
        end
      end

      new_conditions
    end

    def create_site_elements(legacy_bars, legacy_goal, rule)
      legacy_bars.map do |legacy_bar|
        setting_keys = ["buffer_message", "buffer_url", "collect_names", "link_url", "message_to_tweet", "pinterest_description", "pinterest_full_name", "pinterest_image_url", "pinterest_url", "pinterest_user_url", "twitter_handle", "url", "url_to_like", "url_to_plus_one", "url_to_share", "url_to_tweet", "use_location_for_url"]
        settings_to_migrate = legacy_goal.data_json.select{|key, value| setting_keys.include?(key) && value.present? }

        ::SiteElement.create! id: legacy_bar.legacy_bar_id || legacy_bar.id,
                      paused: !legacy_bar.active?,
                      element_subtype: determine_element_subtype(legacy_goal),
                      created_at: legacy_bar.created_at.utc,
                      updated_at: legacy_bar.updated_at.utc,
                      target_segment: legacy_bar.target_segment,
                      rule_id: rule.id,
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
