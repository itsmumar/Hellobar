class HbTestSite
  ROOT = 'test_site'.freeze
  DEFAULT_FILE = 'public/test.html'.freeze
  SINATRA_FILE = 'test_site.rb'.freeze

  def self.path(relative_path = '')
    Rails.root.join(ROOT, relative_path)
  end

  def self.default_site_id
    Site.last.id
  end

  def self.default_path
    path(DEFAULT_FILE)
  end

  def self.generate(site_id, full_path)
    raise 'site id is empty' if site_id.blank?
    generator = SiteGenerator.new(site_id, full_path: full_path)
    generator.generate_file
  end

  def self.generate_default(site_id = nil)
    site_id ||= default_site_id
    generate(site_id, default_path)
  end

  def self.run_file
    path(SINATRA_FILE).to_s
  end
end

namespace :test_site do
  desc "Creates a temp html file with site script at specified location\n rake test_site:file[95,'/Users/polymathic/Desktop/test.html']"
  task :file, %i[site_id file_path] => :environment do |_t, args|
    HbTestSite.generate(args[:site_id], args[:file_path])
  end

  desc "Creates a test.html file in the test_site sinatra folder\n rake test_site:generate[95]\nDefaults to last site if not passed"
  task :generate, [:site_id] => :environment do |_t, args|
    puts "Generating #{ HbTestSite.default_path } for site ##{ args[:site_id] }..."
    HbTestSite.generate_default(args[:site_id])
  end

  desc 'Runs the sinatra server for the test site'
  task :run do
    begin
      ruby  HbTestSite.run_file.to_s
    rescue Interrupt => _
      sleep 1 # wait for sinatra shutdown
      puts 'Good bye! :)'
    end
  end

  desc 'Runs the test site generation and a Sinatra server'
  task :run_fresh, [:site_id] => %i[generate run]
end
