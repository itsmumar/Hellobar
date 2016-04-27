namespace :site do
  namespace :scripts do
    desc 'Schedule a re-generation of ALL site scripts'
    task :regenerate_all => :environment do |t, args|
      Site.find_each do |site|
        site.generate_script(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end

    desc 'Schedule a re-generation of all active site scripts'
    task :regenerate_all_active => :environment do |t, args|
      Site.script_installed_db.each do |site|
        if site.script_generated_at > 3.hour.ago
          site.check_installation(queue_name: Hellobar::Settings[:low_priority_queue])
        else
          site.generate_script_and_check_installation(queue_name: Hellobar::Settings[:low_priority_queue])
        end
      end

      # See if anyone who uninstalled has installed
      Site.where('script_uninstalled_at IS NOT NULL AND script_uninstalled_at > script_installed_at AND (script_uninstalled_at > ? OR script_generated_at > script_uninstalled_at)', Time.now-30.days).each do |site|
        site.check_installation(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end
  end
end
