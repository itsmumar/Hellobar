namespace :legacy_migration do
  desc 'Migrate old data into new schema'
  task do_it_now: :environment do
    LegacyMigrator.migrate
  end

  desc 'Integration test for migration'
  task test: :environment do
    raise 'You must run this task in test mode.' unless Rails.env == 'test'

    unless LegacyMigrator::LegacySite.find(2155).try(:base_url) == 'http://smashy.com'
      raise 'You need to load the test data into your local legacy db. If you need the dump file, talk to Joey.'
    end

    Rake::Task['db:test:clone'].invoke

    LegacyMigrator.migrate

    raise "Migrator didn't import all sites correctly." unless Site.count == 187

    Rake::Task['legacy_migration:run_tests'].invoke
  end

  desc 'Migrate 2.0 users that were present in 1.0 and skipped the first time'
  task migrate_1_point_0_users: :environment do
    wp_emails = {}

    Rails.root.join('db', 'wp_logins.csv').read.split("\n").each_with_index do |line, i|
      next unless i > 0
      e1, e2 = *line.split("\t")
      wp_emails[e1] = true
      wp_emails[e2] = true
    end

    legacy_users = LegacyMigrator::LegacyUser.where(email: wp_emails.keys)

    legacy_users.each do |legacy_user|
      if User.where(id: legacy_user.id_to_migrate).first
        puts "Could not migrate Legacy User #{ legacy_user.id }: ID already exists"
      elsif User.where(email: legacy_user.email).first
        puts "Could not migrate Legacy User #{ legacy_user.id }: email already exists"
      else
        user = User.new(
          id: legacy_user.id_to_migrate,
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
        )

        user.save(validate: false)

        legacy_user.accounts.first.sites.each do |legacy_site|
          site = Site.where(id: legacy_site.id).first
          if site
            user.site_memberships.new(site_id: legacy_site.id).save(validate: false)
          else
            puts "Legacy Site #{ legacy_site.id } was not migrated the first time"
          end
        end
      end
    end
  end

  Rake::TestTask.new(:run_tests) do |t|
    t.test_files = FileList['lib/legacy_migrator/tests/*_test.rb']
  end
end
