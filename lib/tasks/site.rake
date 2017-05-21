namespace :site do
  namespace :scripts do
    desc 'Precompile assets (js, css, html) which are used in site script'
    task precompile_static_assets: :environment do
      StaticScriptAssets.precompile
    end

    desc 'Schedule a re-generation of ALL site scripts'
    task regenerate_all: :environment do
      Site.find_each do |site|
        GenerateDailyStaticScriptJob.perform_later site
      end
    end

    desc 'Schedule a re-generation of all active site scripts'
    task regenerate_all_active: :environment do
      Site.script_installed_db.find_each do |site|
        GenerateDailyStaticScriptJob.perform_later site
        CheckScriptStatusJob.perform_later site
      end

      # See if anyone who uninstalled has installed
      Site.script_was_installed_again.each do |site|
        CheckScriptStatusJob.perform_later site
      end
    end
  end

  namespace :rules do
    desc 'Make sure all sites have all of the default rule presets'
    task add_presets: :environment do |_t, _args|
      sites_without_mobile_rule = Site.joins("LEFT OUTER JOIN rules ON rules.site_id = sites.id AND rules.name = 'Mobile Visitors'")
                                      .where('rules.id IS NULL')

      sites_without_mobile_rule.find_each do |site|
        site.skip_script_generation = true
        mobile_rule = site.rules.defaults[1]
        finder_params = { name: mobile_rule.name, editable: false }
        mobile_rule.save! unless site.rules.find_by(finder_params)
      end

      sites_without_homepage_rule = Site.joins("LEFT OUTER JOIN rules ON rules.site_id = sites.id AND rules.name = 'Homepage Visitors'")
                                        .where('rules.id IS NULL')

      sites_without_homepage_rule.find_each do |site|
        site.skip_script_generation = true
        homepage_rule = site.rules.defaults[2]
        finder_params = { name: homepage_rule.name, editable: false }
        homepage_rule.save! unless site.rules.find_by(finder_params)
      end
    end

    desc 'Remove rule presents from all sites'
    task remove_specific_presets: :environment do |_t, _args|
      Rule.where(name: 'Mobile Visitors', editable: false).destroy_all
      Rule.where(name: 'Homepage Visitors', editable: false).destroy_all
    end
  end
end
