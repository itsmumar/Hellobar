namespace :legacy_migration do
  desc 'Migrate old data into new schema'
  task :do_it_now => :environment do
    LegacyMigrator.migrate
  end
end
