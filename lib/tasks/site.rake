namespace :site do
  namespace :scripts do
    desc 'Schedule a re-generation of all active site scripts'
    task :generate_all_separately => :environment do |t, args|
      Site.script_installed_db.each do |site|
        site.generate_script_and_check_installation(queue_name: Hellobar::Settings[:low_priority_queue])
      end
      # See if anyone who uninstalled has installed
      Site.where('script_uninstalled_at IS NOT NULL AND script_uninstalled_at > script_installed_at AND (script_uninstalled_at > ? OR script_generated_at > script_uninstalled_at)', Time.now-30.days).each do |site|
        site.check_installation(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end

    desc 'Rechecks all installations'
    task :recheck_all_site_installations => :environment do |t, args|
      Site.each do |site|
        site.recheck_installation(queue_name: Hellobar::Settings[:low_priority_queue])
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
