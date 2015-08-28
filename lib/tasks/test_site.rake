class HbTestSite
  ROOT = "test_site"
  DEFAULT_FILE = "public/test.html"
  SINATRA_FILE = "test_site.rb"

  def self.path(relative_path = "")
    Rails.root.join(ROOT, relative_path)
  end

  def self.default_site_id
    Site.last.id
  end

  def self.generate(site_id, full_path)
    generator = SiteGenerator.new(site_id, full_path: full_path)
    generator.generate_file
  end

  def self.generate_default(site_id = nil)
    site_id ||= default_site_id
    full_path = path(DEFAULT_FILE)
    generate(site_id, full_path)
  end

  def self.run_file
    path(SINATRA_FILE).to_s
  end
end

namespace :test_site do
  desc "Creates a temp html file with site script at specified location\n rake test_site:file[95,'/Users/polymathic/Desktop/test.html']"
  task :file, [:site_id, :file_path] => :environment do |t, args|
    HbTestSite.generate(args[:site_id], full_path: args[:file_path])
  end

  desc "Creates a test.html file in the test_site sinatra folder\n rake test_site:generate[95]\nDefaults to last site if not passed"
  task :generate, [:site_id] => :environment do |t, args|
    HbTestSite.generate_default(args[:site_id])
  end

  desc "Runs the sinatra server for the test site"
  task :run do
    ruby "#{HbTestSite.run_file}"
  end
end
