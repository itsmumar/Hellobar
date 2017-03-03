module Hello::EmailDigest
  include EmailDigestHelper

  class << self
    def send(site)
      site.owners_and_admins.each do |recipient|
        mailer = mailer_for_site(site, recipient)
        return if mailer.nil? || mailer.is_a?(ActionMailer::Base::NullMail) || mailer.html_part.nil?

        end_date = EmailDigestHelper.date_of_previous('Sunday')
        start_date = end_date - 6

        options = {content: mailer.html_part.body.raw_source,
                    text: mailer.text_part.body.raw_source,
                    site_url: site.url,
                    date: start_date.strftime('%b %-d') + ' - ' + end_date.strftime(end_date.month == start_date.month ? '%-d, %Y' : '%b %-d, %Y')}

        Analytics.track(:user, recipient.id, 'Sent Email', {'Email Template'=>EmailDigestHelper.template_name(site)})
        MailerGateway.send_email(EmailDigestHelper.template_name(site), recipient.email, options)
      end
    end

    def mailer_for_site(site, user)
      return nil if site.site_elements.active.count == 0

      if site.has_script_installed?
        return DigestMailer.weekly_digest(site, user)
      elsif site.site_elements.where('site_elements.created_at > ?', 10.days.ago).count > 0
        if site.script_installed_at.nil? # Only send if the site never had it installed in the first place
          return DigestMailer.not_installed(site, user)
        end
      else
        nil
      end
    end
  end
end
