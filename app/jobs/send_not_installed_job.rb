class SendNotInstalledJob < ApplicationJob
  def perform(site)
    site.owners_and_admins.each do |user|
      SiteMailer.not_installed(site, user).deliver_now
    end
  end
end
