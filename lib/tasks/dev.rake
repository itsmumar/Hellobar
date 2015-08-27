namespace :dev do
  desc "Creates a temp site with site script at specified location\n rake dev:test_site[95, '/Users/polymathic/Desktop/test.html']"
  task :test_site, [:site_id, :file_path] => :environment do |t, args|
    generator = SiteGenerator.new(args[:site_id], full_path: args[:file_path])
    generator.generate_file
  end
end
