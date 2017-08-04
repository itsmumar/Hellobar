class SendSiteScriptNotInstalledEmailJob < ApplicationJob
  def perform(site)
    site.owners_and_admins.each do |user|
      SiteMailer.site_script_not_installed(site, user).deliver_now
    end
  end
end
