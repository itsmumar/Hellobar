namespace :mailing do
  task send_weekly_digest: :environment do
    Site.script_installed_db.weekly_digest_optin.find_each do |site|
      SendWeeklyDigestEmailJob.perform_later site
    end
  end

  task send_site_script_not_installed: :environment do
    Site.script_not_installed_but_active.find_each do |site|
      SendSiteScriptNotInstalledEmailJob.perform_later site
    end
  end
end
