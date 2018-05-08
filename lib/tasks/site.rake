namespace :site do
  namespace :scripts do
    desc 'Precompile assets (js, css, html) which are used in the static site script'
    task precompile_static_assets: :environment do
      StaticScriptAssets.precompile
    end

    desc 'Generate and upload modules.js to S3'
    task generate_modules: :environment do
      GenerateStaticScriptModules.new.call
      puts "Uploaded new modules.js version to S3: #{ StaticScriptAssets.digest_path('modules.js') }"
    end

    namespace :regenerate do
      desc 'Regenerate static site scripts for all non-deleted sites'
      task all: :environment do
        Site.find_each do |site|
          GenerateStaticScriptLowPriorityJob.perform_later site
        end
      end

      desc 'Regenerate static site scripts for all active sites'
      task all_active: :environment do
        Site.script_installed.find_each do |site|
          GenerateStaticScriptLowPriorityJob.perform_later site
        end
      end

      desc 'Regenerate static site scripts for active sites (take 200 least recently regenerated sites)'
      task sample_of_least_recently_regenerated_active_sites: :environment do
        # Take 200 sites at one go; it will take ~24 hours to regenerate static
        # site script for up to 40K installed sites (we have about 30K installed
        # sites)
        # (#each and not #find_each, to respect #limit)
        Site
          .script_installed
          .where('script_generated_at < ?', 12.hours.ago)
          .order(:script_generated_at)
          .limit(200).each do |site|
            GenerateStaticScriptLowPriorityJob.perform_later site

            # We also check static script installation at the same time (we do
            # it here out of convenience as we don't store the time when we did
            # last install check for each site)
            CheckStaticScriptInstallation.new(site).call
          end
      end
    end

    namespace :install_check do
      desc 'Install check for recently uninstalled sites'
      task recently_uninstalled: :environment do
        # around 2-4K; we can deal with them at one go every day
        Site.script_recently_uninstalled.find_each do |site|
          CheckStaticScriptInstallation.new(site).call
        end
      end

      desc 'Install check for uninstalled sites recently modified'
      task uninstalled_but_recently_modified: :environment do
        # up to 2K; we can deal with them at one go every day
        Site.script_uninstalled_but_recently_modified.find_each do |site|
          CheckStaticScriptInstallation.new(site).call
        end
      end

      desc 'Install check for recently created sites with uninstalled script'
      task recently_created_not_installed: :environment do
        # up to 5K; we can deal with them at one go every day
        Site.recently_created.script_not_installed.find_each do |site|
          CheckStaticScriptInstallation.new(site).call
        end
      end
    end
  end
end
