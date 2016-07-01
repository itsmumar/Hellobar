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

      sites_without_mobile_rule = Site.joins("LEFT OUTER JOIN rules ON rules.site_id = sites.id AND rules.name = 'Mobile Visitors'").
                                       where("rules.id IS NULL")

      sites_without_mobile_rule.find_each do |site|
        # disable script generation while adding rule presets to sites
        def site.generate_script; nil; end # rubocop:disable Style/SingleLineMethods

        mobile_rule = site.rules.defaults[1]
        finder_params = {name: mobile_rule.name, editable: false}
        mobile_rule.save! unless site.rules.find_by(finder_params)
      end

      sites_without_homepage_rule = Site.joins("LEFT OUTER JOIN rules ON rules.site_id = sites.id AND rules.name = 'Homepage Visitors'").
                                         where("rules.id IS NULL")

      sites_without_homepage_rule.find_each do |site|
        # disable script generation while adding rule presets to sites
        def site.generate_script; nil; end # rubocop:disable Style/SingleLineMethods

        homepage_rule = site.rules.defaults[2]
        finder_params = {name: homepage_rule.name, editable: false}
        homepage_rule.save! unless site.rules.find_by(finder_params)
      end
    end

    desc 'Remove rule presents from all sites'
    task :remove_specific_presets => :environment do |t, args|
      Rule.where(name: "Mobile Visitors", editable: false).destroy_all
      Rule.where(name: "Homepage Visitors", editable: false).destroy_all
    end
  end
end
