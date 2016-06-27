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

  namespace :rules do
    desc 'Make sure all sites have all of the default rule presets'
    task :add_presets => :environment do |t, args|
      Site.all.each do |site|
        site.rules.defaults.each do |rule|
          finder_params = {name: rule.name, editable: false}
          rule.save! unless site.rules.find_by(finder_params)
        end
      end

      invalid_sites = Site.joins(:rules).
                           where("rules.editable = ?", false).
                           group("sites.id").
                           having("count(rules.id) != ?", Rule.defaults.size)

      unless invalid_sites.to_a.size == 0
        raise "All sites must have 3 default/un-editable rules"
      end
    end

    desc 'Remove rule presents from all sites'
    task :remove_specific_presets => :environment do |t, args|
      Rule.where(name: "Mobile Visitors", editable: false).destroy_all
      Rule.where(name: "Homepage Visitors", editable: false).destroy_all
    end
  end
end
