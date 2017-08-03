class SiteMailer < ActionMailer::Base
  include Roadie::Rails::Mailer
  include EmailDigestHelper
  add_template_helper(EmailDigestHelper)

  default from: 'Hello Bar <contact@hellobar.com>'

  before_filter :set_weekly_dates

  def weekly_digest(site, user)
    @site = site
    @user = user

    @site_statistics = fetch_site_statistics
    @last_week_statistics = @site_statistics.within(@last_week)
    @week_before_statistics = @site_statistics.within(@week_before)
    @sorted_elements = site_elements_to_send(site)
    @conversion_header = conversion_header(@sorted_elements)

    roadie_mail(
      to: user.email,
      subject: "Hello Bar Weekly Digest for #{ site.url } - #{ week_for_subject }"
    )
  end

  def not_installed(site, user)
    @site = site
    @user = user

    roadie_mail(
      to: user.email,
      subject: 'One final step and your Hello bar is live'
    )
  end

  private

  def fetch_site_statistics
    FetchSiteStatistics.new(@site, days_limit: @site.capabilities.num_days_improve_data).call
  end

  def set_weekly_dates
    last_sunday = EmailDigestHelper.date_of_previous('Sunday')
    @week_before = 13.days.until(last_sunday)..7.days.until(last_sunday)
    @last_week = 6.days.until(last_sunday)..last_sunday
  end

  def site_elements_to_send(site)
    site.site_elements.where(id: @last_week_statistics.with_views.site_element_ids)
  end
end
