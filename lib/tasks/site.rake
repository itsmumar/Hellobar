namespace :site do
  namespace :scripts do
    desc 'Schedule a re-generation of all active site scripts'
    task :generate_all_separately => :environment do |t, args|
      Site.find_each do |site|
        site.generate_script(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end
  end
end
