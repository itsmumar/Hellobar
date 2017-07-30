class SendNotInstalledJob < ApplicationJob
  def perform(site)
    site.owners_and_admins.each do |user|
      DigestMailer.not_installed(site, user).deliver_now
    end
  end
end
