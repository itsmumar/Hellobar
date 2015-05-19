module Hello::EmailDigest
  include EmailDigestHelper

  class << self
    def send(site)
      mailer = mailer_for_site(site)
      return if mailer.nil?

      end_date = EmailDigestHelper.date_of_previous("Sunday")
      start_date = end_date - 6

      options = {content: mailer.html_part.body.raw_source,
                  text: mailer.text_part.body.raw_source,
                  site_url: site.url,
                  date: start_date.strftime("%b %-d") + " - " + end_date.strftime(end_date.month == start_date.month ? "%-d, %Y" : "%b %-d, %Y")}
      Analytics.track(:user, site.owner.id, "Sent Email", {"Email Template"=>EmailDigestHelper.template_name(site)})
      MailerGateway.send_email(EmailDigestHelper.template_name(site), site.owner.email, options)
    end

    def mailer_for_site(site)
      return nil if site.site_elements.count == 0

      if site.has_script_installed?
        DigestMailer.weekly_digest(site)
      elsif site.site_elements.where("site_elements.created_at > ?", 10.days.ago).count > 0
        DigestMailer.not_installed(site)
      else
        nil
      end
    end
  end
end
