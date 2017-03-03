require_relative './legacy_migrator/legacy_model'

class LegacyMigrator
  class << self
    def migrate
      ActiveRecord::Base.record_timestamps = false
      ActiveRecord::Base.connection.execute("SET unique_checks=0")
      ActiveRecord::Base.connection.execute("SET foreign_key_checks=0")

      # propagate any exceptions raised in a thread
      Thread::abort_on_exception = true

      @migrated_memberships = {}
      puts "[#{Time.now}] Start"
      load_wp_emails
      preload_data
      migrate_sites_and_users_and_memberships
      migrate_identities
      migrate_contact_lists
      migrate_goals_to_rules
      migrate_site_timezones
      migrate_admins

      puts "[#{Time.now}] Done reading, writing..."
      threads = []
      threads << set_subscriptions
      threads << save_to_db(@migrated_memberships)
      threads << save_to_db(@migrated_users)
      threads << save_to_db(@migrated_sites)
      threads << save_to_db(@migrated_identities)
      threads << save_to_db(@migrated_contact_lists)
      threads << save_to_db(@migrated_rules)
      threads.each(&:join)
      save_to_db(@rules_to_migrate_later) # must happen after initial rules are created to prevent ID collision
      puts "[#{Time.now}] Done writing"
      # Probably a good idea to load the subscriptions into the site object for
      # checking capabbilities, etc

      ActiveRecord::Base.record_timestamps = true
    end

    def set_subscriptions
      # Override for faster capabilities checking
      Site.send(:define_method, :capabilities) do
        return Subscription::FreePlus::Capabilities.new(nil, self)
      end
      now = Time.now
      one_month_from_now = now + 1.month
      two_months_from_now = one_month_from_now + 1.month
      escaped_now = ActiveRecord::Base.sanitize(now)
      escaped_one_month_from_now = ActiveRecord::Base.sanitize(one_month_from_now)
      escaped_two_months_from_now = ActiveRecord::Base.sanitize(two_months_from_now)
      subscription_id = 0
      optimize_inserts do
        puts "[#{Time.now}] Done writing, changing subscription..."
        @migrated_sites.each do |key, site|
          # Direct inserts
          ActiveRecord::Base.connection.execute("INSERT INTO #{Subscription.table_name} VALUES (NULL, NULL, #{site.id}, 'Subscription::FreePlus', 0, 0.00, 25000, NULL, NULL, #{escaped_now}, NULL)")
          subscription_id += 1
          # This bill and next bill
          ActiveRecord::Base.connection.execute("INSERT INTO #{Bill.table_name} VALUES
          (NULL, #{subscription_id}, 1, 'Bill::Recurring', 0.00, NULL, NULL, 0, #{escaped_now}, #{escaped_now}, #{escaped_one_month_from_now}, #{escaped_now}, #{escaped_now}),
          (NULL, #{subscription_id}, 0, 'Bill::Recurring', 0.00, 'Monthly Renewal', NULL, 1, #{escaped_one_month_from_now}, #{escaped_one_month_from_now}, #{escaped_two_months_from_now}, NULL, #{escaped_now})")
          puts "[#{Time.now}] Changing subscription #{subscription_id}..." if subscription_id % 5000 == 0
        end
        puts "[#{Time.now}] Done inserting subscriptions"
      end
    end

    def optimize_inserts
      Thread.new do
        yield
      end
    end

    def save_to_db(items)
      klass =  items[items.keys.first].class
      count = 0
      optimize_inserts do
        items.each do |key, item|
          if item.kind_of?(Array)
            klass = item.first.class
            count += 1
            puts "[#{Time.now}] Saving #{count} #{klass}..." if count % 5000 == 0
            item.each{|i| i.save(validate: false)}
          else
            count += 1
            puts "[#{Time.now}] Saving #{count} #{klass}..." if count % 5000 == 0
            item.save(validate: false)
          end
        end
      end
    end

=begin
    The following method yielded a 2x improvement, but skipped callbacks
    and probably has other issues. Keeping for posterity's sake
    def save_to_db_via_csv(items)
      klass =  items[items.keys.first].class
      count = 0

      columns = klass.column_names
      csv_file = File.join(Rails.root, "#{klass.name.underscore}.csv")
      CSV.open(csv_file, "w") do |csv|
        items.each do |key, item|
          count += 1
          puts "[#{Time.now}] Saving #{count} #{klass}..." if count % 500 == 0
          # item.save(validate: false)
          csv << columns.collect{|c| klass.sanitize(item.send(c)).gsub(/^'(.*)'$/,"\\1")}
        end
      end
      `chmod 777 #{csv_file}`
      `sudo mv #{csv_file} /var/lib/mysql/hellobar/`
      ActiveRecord::Base.transaction do
        optimize_inserts do
          ActiveRecord::Base.connection.execute(%{LOAD DATA INFILE '#{File.basename(csv_file)}' INTO TABLE #{klass.table_name} FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'})
        end
      end
      # `sudo rm /var/lib/mysql/hellobar/#{File.basename(csv_file}`
    end
=end

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
      @legacy_bars = preload(LegacyMigrator::LegacyBar, :goal_id, :collection)
      @legacy_goals = preload(LegacyMigrator::LegacyGoal)
      @legacy_identity_integrations = preload(LegacyMigrator::LegacyIdentityIntegration, :integrable_id)

      # keyed off site_id for faster lookup
      @legacy_goals_by_site_id = {}
      @legacy_goals.each do |key, legacy_goal|
        @legacy_goals_by_site_id[legacy_goal.site_id] ||= []
        @legacy_goals_by_site_id[legacy_goal.site_id] << legacy_goal
      end

      @migrated_users = {}
      @migrated_sites = {}
      @migrated_rules = {}
      @rules_to_migrate_later = {}
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
                            updated_at: legacy_site.updated_at.utc,
                            read_key: SecureRandom.uuid,
                            write_key: SecureRandom.uuid,
                            opted_in_to_email_digest: legacy_site.settings_json["email_digest"] == "1"

          create_user_and_membership legacy_site_id: site.id,
                                     account_id: legacy_site.account_id

          @migrated_sites[site.id] = site
          count += 1
          puts "[#{Time.now}] Migrated #{count} sites" if count % 5000 == 0
        rescue ActiveRecord::RecordInvalid => e
          raise e.inspect
        end
      end
    end

    def migrate_goals_to_rules
      goal_count = 0

      @migrated_sites.each do |key, site|
        if @legacy_goals_by_site_id[site.id].present?
          # create rules, conditions, and site elements
          @legacy_goals_by_site_id[site.id].each do |legacy_goal|
            # legacy bars are keyed off goal ID

            mobile_bars, non_mobile_bars = @legacy_bars[legacy_goal.id].partition{|bar| bar_is_mobile?(bar) }

            if non_mobile_bars.present?
              rule = ::Rule.new(id: legacy_goal.id, site_id: site.id, name: 'Everyone', priority: legacy_goal.priority, match: Rule::MATCH_ON[:all], created_at: legacy_goal.created_at.utc, updated_at: legacy_goal.updated_at.utc)

              # build conditions
              create_conditions(rule, legacy_goal) # condition added to rule in-memory

              # build site elements
              create_site_elements(rule, non_mobile_bars, legacy_goal)

              @migrated_rules[site.id] ||= []
              @migrated_rules[site.id] << rule
            end

            if mobile_bars.present?
              rule = ::Rule.new(id: nil, site_id: site.id, name: 'Everyone', priority: legacy_goal.priority, match: Rule::MATCH_ON[:all], created_at: legacy_goal.created_at.utc, updated_at: legacy_goal.updated_at.utc)

              create_conditions(rule, legacy_goal) # conditions added to rule in-memory
              # build a mobile DeviceCondition for mobile bars only
              rule.conditions.build operand: 'is', value: 'mobile', segment: 'DeviceCondition'

              # build site elements
              create_site_elements(rule, mobile_bars, legacy_goal)

              @rules_to_migrate_later[site.id] ||= []
              @rules_to_migrate_later[site.id] << rule
            end

            goal_count += 1
            puts "[#{Time.now}] Migrated #{goal_count} goals to rules" if goal_count % 100 == 0

            if non_mobile_bars.empty? && mobile_bars.empty?
              Rails.logger.info "WTF: Legacy Goal #{legacy_goal.id} has no bars!"
              next
            end
          end

        else # site has no rules so give them a default rule
          rule = Rule.new(:name => "Everyone",
                          :match => Rule::MATCH_ON[:all],
                          :site => site)

          @rules_to_migrate_later[site.id] ||= []
          @rules_to_migrate_later[site.id] << rule
        end
      end

      # check for duplicate rules
      @migrated_rules.each do |site_id, rules|
        rules.each do |rule|
          next unless @migrated_rules[rule.site_id].include?(rule)

          existing_rules(rule).each do |existing|
            existing.site_elements.each do |element|
              rule.site_elements << element
            end

            @migrated_rules[rule.site_id].delete(existing)
          end
        end
      end

      # rename rules if we need to based on the # of conditions
      [@migrated_rules, @rules_to_migrate_later].each do |rule_group|
        rule_group.each do |site_id, rules|
          rules.each do |rule|
            if rule.conditions.any?
              site_rules = (@migrated_rules[site_id] || []) + (@rules_to_migrate_later[site_id] || [])
              segment_name = rule.conditions.first.segment_data[:name]
              index = site_rules.select{|r| r.conditions.any? && r.conditions.first.segment_data[:name] == segment_name}.index(rule) + 1

              rule.name = "#{segment_name} Rule ##{index}"
            end
          end
        end
      end
    end

    def create_site_elements(rule, legacy_bars, legacy_goal)
      legacy_bars.each do |legacy_bar|
        setting_keys = %w(buffer_message buffer_url fields_to_collect link_url message_to_tweet pinterest_description pinterest_full_name pinterest_image_url pinterest_url pinterest_user_url twitter_handle url url_to_like url_to_plus_one url_to_share url_to_tweet use_location_for_url url)
        settings_to_migrate = legacy_goal.data_json.select{|key, value| setting_keys.include?(key) && value.present? }

        rule.site_elements.build id: legacy_bar.legacy_bar_id || legacy_bar.id,
                                 paused: !legacy_bar.active?,
                                 element_subtype: determine_element_subtype(legacy_goal),
                                 created_at: legacy_bar.created_at.utc,
                                 updated_at: legacy_bar.updated_at.utc,
                                 target_segment: legacy_bar.target_segment,
                                 closable: legacy_bar.settings_json['closable'],
                                 show_border: false,
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
                                 contact_list: @migrated_contact_lists[legacy_goal.id]
      end
    end

    # a rule for site which already exists and has same conditions
    def existing_rules(rule)
      @migrated_rules[rule.site_id].select { |r| rules_equal?(rule, r) && rule != r }
    end

    def rules_equal?(rule_one, rule_two)
      rule_one_conditions = rule_one.conditions
      rule_two_conditions = rule_two.conditions

      if rule_one_conditions.empty? && rule_two_conditions.empty?
        true
      elsif rule_one_conditions.size != rule_two_conditions.size
        false
      elsif rule_one_conditions.size > 1 && rule_one.match != rule_two.match
        false
      else
        rule_one.conditions.all? do |condition|
          rule_two_conditions.any? do |other_condition|
            condition.segment == other_condition.segment &&
              condition.operand == other_condition.operand &&
              condition.value == other_condition.value
          end
        end
      end
    end

    # returns true/false if the bar is targeting mobile users
    def bar_is_mobile?(bar)
      bar.target_segment == 'dv:mobile' ||
        bar.settings_json['target'] == 'dv:mobile'
    end

    def migrate_contact_lists
      count = 0

      @migrated_contact_lists = {}
      @migrated_contact_lists_by_site = {}
      @legacy_goals.each do |id, legacy_goal|
        next unless legacy_goal.type == "Goals::CollectEmail"

        unless @migrated_sites[legacy_goal.site_id]
          Rails.logger.info "WTF:Legacy Site: #{legacy_goal.site_id} doesnt exist for Goal: #{legacy_goal.id}"
          next
        end

        params = {
          id: legacy_goal.id,
          site_id: legacy_goal.site_id,
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

        contact_list = ::ContactList.new(params)
        @migrated_contact_lists[contact_list.id] = contact_list
        @migrated_contact_lists_by_site[contact_list.site_id] ||= []
        @migrated_contact_lists_by_site[contact_list.site_id] << contact_list

        count += 1
        puts "[#{Time.now}] Migrated #{count} contact lists" if count % 100 == 0
      end

      @migrated_contact_lists.each do |id, list|
        if list.name.nil?
          index = @migrated_contact_lists_by_site[list.site_id].index(list)
          list.name = index == 0 ? "My Contacts" : "My Contacts #{index + 1}"
        end
      end
    end

    def migrate_identities
      count = 0
      @migrated_identities = {}
      @legacy_identities = preload(LegacyMigrator::LegacyIdentity)
      @legacy_identities.each do |id, legacy_id|
        if site = @legacy_sites[legacy_id.site_id]
          identity = ::Identity.new id: legacy_id.id,
                             site_id: legacy_id.site_id,
                             provider: legacy_id.provider,
                             credentials: legacy_id.credentials,
                             extra: legacy_id.extra,
                             created_at: legacy_id.created_at,
                             updated_at: legacy_id.updated_at

          count += 1
          @migrated_identities[identity.id] = identity
          puts "[#{Time.now}] Migrated #{count} identities" if count % 100 == 0
        else
          Rails.logger.info "WTF:Legacy Site: #{legacy_id.site_id} doesnt exist for Identity: #{legacy_id.id}"
        end
      end
    end

    def migrate_admins
      LegacyMigrator::LegacyAdmin.find_each do |legacy_admin|
        admin = Admin.new(
          id: legacy_admin.id,
          email: legacy_admin.email,
          mobile_phone: legacy_admin.mobile_phone,
          password_hashed: legacy_admin.password_hashed,
          mobile_code: legacy_admin.mobile_code,
          session_token: legacy_admin.session_token,
          session_access_token: legacy_admin.session_access_token,
          password_last_reset: legacy_admin.password_last_reset,
          session_last_active: legacy_admin.session_last_active,
          mobile_codes_sent: legacy_admin.mobile_codes_sent,
          login_attempts: legacy_admin.login_attempts,
          valid_access_tokens: JSON.parse(legacy_admin.valid_access_tokens_json || "{}"),
          locked: legacy_admin.locked
        )

        admin.save(validate: false)
      end
    end

    def migrate_site_timezones
      @legacy_sites.each do |site_id, legacy_site|
        next unless legacy_goals = @legacy_goals_by_site_id[site_id]
        timezones = legacy_goals.map{|goal| timezone_for_goal(goal)}.compact.uniq

        # update the new Site with the first timezone
        if timezones.length >= 1
          @migrated_sites[site_id].timezone = timezones.first
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
      start_date = legacy_goal.data_json['start_date']
      end_date = legacy_goal.data_json['end_date']
      include_urls = legacy_goal.data_json['include_urls'] || []
      does_not_include_urls = legacy_goal.data_json['exclude_urls'] # legacy key is exclude_urls, which we map to does_not_include

      date_condition = Condition.date_condition_from_params(start_date, end_date)

      # add conditionto in-memory rule
      if date_condition
        rule.conditions.build operand: date_condition.operand,
                              value: date_condition.value,
                              segment: 'DateCondition'
      end

      if include_urls.present?
        rule.conditions.build operand: :is,
                              value: include_urls,
                              segment: 'UrlCondition'
      end

      if does_not_include_urls.present?
        rule.conditions.build operand: :is_not,
                              value: does_not_include_urls,
                              segment: 'UrlCondition'
      end
    end

    def determine_element_subtype(legacy_goal)
      case legacy_goal.type
      when "Goals::DirectTraffic"
        "traffic"
      when "Goals::CollectEmail"
        "email"
      when "Goals::SocialMedia"
        "social/#{legacy_goal.data_json['interaction']}"
      end
    end
  end
end
