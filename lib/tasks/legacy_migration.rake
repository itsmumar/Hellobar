namespace :legacy_migration do
  desc 'Migrate User data into new schema'
  task :users => :environment do
    LegacyMigrator.migrate :users
  end

  desc 'Migrate Membership data into Site Membership schema'
  task :memberships => :environment do
    LegacyMigrator.migrate :memberships
  end

  desc 'Migrate Site data into new schema'
  task :sites => :environment do
    LegacyMigrator.migrate :sites
  end

  desc 'Migrate Goal data into RuleSet schema'
  task :goals => :environment do
    LegacyMigrator.migrate :goals
  end

  desc 'Migrate Bar data into new schema'
  task :bars => :environment do
    LegacyMigrator.migrate :bars
  end

  desc 'Migrate all old data into new schema'
  task :everything => [:sites, :users, :memberships, :goals, :bars]
end
