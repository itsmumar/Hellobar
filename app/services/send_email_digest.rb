class SendEmailDigest
  def initialize(site)
    @site = site
  end

  def call
    site.owners_and_admins.each do |recipient|
      Analytics.track(:user, recipient.id, 'Sent Email', 'Email Template' => template_name)
      mailer_for(recipient)&.deliver_now
    end
  end

  private

  attr_reader :site

  def mailer_for(user)
    if site.script_installed?
      DigestMailer.weekly_digest(site, user)
    elsif should_send_not_installed?
      DigestMailer.not_installed(site, user)
    end
  end

  def should_send_not_installed?
    any_elements_created_recently? && site.script_installed_at.nil?
  end

  def any_elements_created_recently
    site.site_elements.where('site_elements.created_at > ?', 10.days.ago).any?
  end

  def template_name
    EmailDigestHelper.template_name(site)
  end
end
