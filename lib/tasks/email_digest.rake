namespace :email_digest do
  task deliver: :environment do
    Site.for_weekly_digest.find_each do |site|
      SendWeeklyDigestJob.perform_later site
    end

    Site.for_not_installed_reminder.find_each do |site|
      SendNotInstalledJob.perform_later site
    end
  end
end
