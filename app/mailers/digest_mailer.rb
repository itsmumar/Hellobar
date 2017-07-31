class DigestMailer < ActionMailer::Base
  include Roadie::Rails::Mailer
  include EmailDigestHelper
  include Hello::InternalAnalytics
  add_template_helper(EmailDigestHelper)
  default from: 'from@example.com'

  before_filter :set_weekly_dates

  def weekly_digest(site, user)
    @site = site
    @user = user

    # First find the site elements that actually have views
    @site_statistics = FetchSiteStatistics.new(site, days_limit: site.capabilities.num_days_improve_data).call
    @last_week_statistics = @site_statistics.within(@last_week)
    @week_before_statistics = @site_statistics.within(@week_before)

    @sorted_elements = site_elements_to_send(site)
    # Bail if we don't have any elements with data
    return nil if @sorted_elements.empty?
    @conversion_header = conversion_header(@sorted_elements)

    roadie_mail(
      to: '', # Doesn't matter, we're sending the results through Grand Central
      subject: 'Your Weekly Hello Bar Digest'
    )
  end

  def not_installed(site, user)
    @site = site
    @user = user

    roadie_mail(
      to: '', # Doesn't matter, we're sending the results through Grand Central
      subject: 'One final step and your Hello Bar is live!'
    )
  end

  private

  def set_weekly_dates
    end_date = EmailDigestHelper.date_of_previous('Sunday')
    @week_before = 13.days.until(end_date)..7.days.until(end_date)
    @last_week = 6.days.until(end_date)..end_date
  end

  def site_elements_to_send(site)
    site.site_elements.where(id: @last_week_statistics.with_views.site_element_ids) || []
  end
end
