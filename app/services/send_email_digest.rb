class SendEmailDigest
  cattr_reader :logger do
    file = Rails.root.join('log', 'send_email_digest.log')
    ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(file))
  end

  def initialize(site)
    @site = site
  end

  def call
    mailers.each do |recipient, mailer|
      options = options_for(mailer)
      Analytics.track(:user, recipient.id, 'Sent Email', 'Email Template' => template_name)
      response = MailerGateway.send_email(template_name, recipient.email, options)
      log_response(response)
    end
  end

  private

  attr_reader :site

  def log_response(response)
    response.each do |email, status|
      message = status.gsub(/\d{10}/) { |timestamp| Time.zone.at(timestamp.to_i) }
      self.class.logger.tagged(Time.current, email) { logger.info message }
    end
  end

  def mailers
    site.owners_and_admins.inject({}) { |hash, recipient|
      hash.update recipient => valid_mailer_for(recipient)
    }.compact
  end

  def options_for(mailer)
    {
      content: mailer.html_part.body.raw_source,
      text: mailer.text_part.body.raw_source,
      site_url: site.url,
      date: start_date.strftime('%b %-d') + ' - ' + end_date.strftime(end_date_format)
    }
  end

  def invalid_mailer?(mailer)
    mailer.nil? || mailer.is_a?(ActionMailer::Base::NullMail) || mailer.html_part.nil?
  end

  def valid_mailer_for(user)
    mailer = mailer_for user
    return if no_elements? || invalid_mailer?(mailer)
    mailer
  end

  def mailer_for(user)
    if site.script_installed?
      DigestMailer.weekly_digest(site, user)
    elsif should_send_not_installed?
      DigestMailer.not_installed(site, user)
    end
  end

  def no_elements?
    site.site_elements.active.count == 0
  end

  def should_send_not_installed?
    site.site_elements.where('site_elements.created_at > ?', 10.days.ago).count > 0 && site.script_installed_at.nil?
  end

  def end_date
    EmailDigestHelper.date_of_previous('Sunday')
  end

  def start_date
    end_date - 6
  end

  def end_date_format
    end_date.month == start_date.month ? '%-d, %Y' : '%b %-d, %Y'
  end

  def template_name
    EmailDigestHelper.template_name(site)
  end
end
