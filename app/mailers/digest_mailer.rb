class DigestMailer < ActionMailer::Base
  include Roadie::Rails::Mailer
  include EmailDigestHelper
  add_template_helper(EmailDigestHelper)
  default from: "from@example.com"

  before_filter :set_weekly_dates

  def weekly_digest(site)
    @site = site

    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @se_totals = Hello::DataAPI.lifetime_totals(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @sorted_elements = site.site_elements.active.sort_by { |se| @se_totals[se.id.to_s].views_between(@date_ranges[2], @date_ranges[3]) }.reverse!
    @conversion_header = conversion_header(@sorted_elements)

    roadie_mail(
      to: site.owner.email,
      subject: 'Your Weekly Hello Bar Digest'
    )
  end

  def not_installed(site)
    @site = site

    roadie_mail(
      to: site.owner.email,
      subject: 'One final step and your Hello Bar is live!'
    )
  end

  private

  def set_weekly_dates
    @end_date = EmailDigestHelper.date_of_previous("Sunday")
    @date_ranges = [@end_date - 13, @end_date - 7, @end_date - 6, @end_date]
  end
end
