namespace :site do
  namespace :scripts do
    desc 'Schedule a re-generation of all active site scripts'
    task :generate_all_separately => :environment do |t, args|
      Site.script_installed_db.each do |site|
        site.generate_script_and_check_for_uninstall(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end
  end

  namespace :improve_suggestions do
    desc 'Schedule a re-generation of all active site improve_suggestions'
    task :generate_all_separately => :environment do |t, args|
      Site.script_installed_db.each do |site|
        site.generate_improve_suggestions(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end
  end
end
