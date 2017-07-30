namespace :email_digest do
  def not_installed_sites_with_elements_created_recently
    Site.joins(:site_elements)
        .where(script_installed_at: nil)
        .where('site_elements.created_at > ?', 10.days.ago)
  end

  def sites_for_weekly_digest
    Site.script_installed_db.where(opted_in_to_email_digest: true)
  end

  task deliver: :environment do
    sites_for_weekly_digest.find_each do |site|
      SendWeeklyDigestJob.perform_later site
    end

    not_installed_sites_with_elements_created_recently.find_each do |site|
      SendNotInstalledJob.perform_later site
    end
  end
end
