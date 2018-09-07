class ResetEmailSentFields
  def initialize(site)
    @site = site
  end

  def call
    reset_site_fields
  end

  private

  attr_reader :site

  def reset_site_fields
    site.update(
      warning_email_one_sent: false,
      warning_email_two_sent: false,
      warning_email_three_sent: false,
      limit_email_sent: false,
      upsell_email_sent: false
    )
  end
end
