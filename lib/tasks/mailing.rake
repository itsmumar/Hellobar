namespace :mailing do
  task send_weekly_digest: :environment do
    Site.for_weekly_digest.find_each do |site|
      SendWeeklyDigestEmailJob.perform_later site
    end
  end

  task send_site_not_installed_reminders: :environment do
    Site.for_not_installed_reminder.find_each do |site|
      SendNotInstalledJob.perform_later site
    end
  end
end
