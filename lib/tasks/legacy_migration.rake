namespace :legacy_migration do
  desc 'Migrate old data into new schema'
  task :do_it_now => :environment do
    LegacyMigrator.migrate
  end

  desc "Integration test for migration"
  task :test => :environment do
    raise "You must run this task in test mode." unless Rails.env == "test"

    unless LegacyMigrator::LegacySite.find(2155).try(:base_url) == "http://smashy.com"
      raise "You need to load the test data into your local legacy db. If you need the dump file, talk to Joey."
    end

    Rake::Task["db:test:clone"].invoke

    LegacyMigrator.migrate

    raise "Migrator didn't import all sites correctly." unless Site.count == 187

    Rake::Task["legacy_migration:run_tests"].invoke
  end

  Rake::TestTask.new(:run_tests) do |t|
    t.test_files = FileList["lib/legacy_migrator/tests/*_test.rb"]
  end
end
