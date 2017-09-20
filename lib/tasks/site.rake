namespace :site do
  namespace :scripts do
    desc 'Precompile assets (js, css, html) which are used in site script'
    task precompile_static_assets: :environment do
      StaticScriptAssets.precompile
      GenerateStaticScriptModules.new.call
      puts "Uploaded new modules.js version to S3: #{ StaticScriptAssets.digest_path('modules.js') }"
    end

    desc 'Schedule a re-generation of ALL site scripts'
    task regenerate_all: :environment do
      Site.find_each do |site|
        GenerateStaticScriptPeriodicallyJob.perform_later site
      end
    end

    desc 'Schedule a re-generation of all active site scripts'
    task regenerate_all_active: :environment do
      Site.script_installed.find_each do |site|
        # TODO: this should be executed uniformly over a period of 24 hours
        GenerateStaticScriptPeriodicallyJob.perform_later site

        # TODO: this should be executed uniformly over a period of 24 hours
        # TODO: this should be executed *independently* (I think?)
        CheckStaticScriptInstallation.new(site).call
      end

      # See if anyone who has uninstalled recently has reinstalled
      # TODO: this should be executed uniformly over a period of 24 hours
      Site.script_uninstalled_recently_or_active.each do |site|
        CheckStaticScriptInstallation.new(site).call
      end
    end
  end
end
