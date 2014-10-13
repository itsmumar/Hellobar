namespace :site do
  desc 'Schedule a re-generation of all active site scripts'
  task :regenerate_all_separately => :environment do |t, args|
    Site.find_each do |site|
      site.generate_script(queue_name: 'hellobar_production_lowpriority')
    end
  end
end
