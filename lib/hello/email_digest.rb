module Hello::EmailDigest
  include EmailDigestHelper

  class << self
    def send(site)
      m = site.has_script_installed? ? DigestMailer.weekly_digest(site) : DigestMailer.not_installed(site)
      options = {content: m.html_part.body.raw_source,
                  text: m.text_part.body.raw_source,
                  site_url: site.url}
      MailerGateway.send_email(EmailDigestHelper.template_name(site), site.owner.email, options)
    end
  end
end
