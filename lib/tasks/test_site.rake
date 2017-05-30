namespace :test_site do
  desc "Creates a temp html file with site script at specified location\n rake test_site:file[95,'/Users/polymathic/Desktop/test_site.html']"
  task :file, %i[site_id file_path] => :environment do |_t, args|
    HbTestSite.generate(args[:site_id], args[:file_path])
  end

  desc "Creates a test_site.html file in the public folder\n rake test_site:generate[95]\nDefaults to most recently updated Site if id is not passed"
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

  desc 'Runs the test site generation and Sinatra server'
  task :run_fresh, [:site_id] => %i[generate run]
end
