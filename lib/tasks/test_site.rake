namespace :test_site do
  desc "Creates a test_site.html file in the public folder\n rake test_site:generate[95]\nDefaults to most recently updated Site if id is not passed"
  task :generate, [:site_id] => :environment do |_t, args|
    puts "Generating #{ HbTestSite.default_path } for site ##{ args[:site_id] }..."
    HbTestSite.generate_default(args[:site_id])
  end
end
