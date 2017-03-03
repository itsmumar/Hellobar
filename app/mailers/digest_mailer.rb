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
    @se_totals = Hello::DataAPI.lifetime_totals(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @sorted_elements = site.site_elements.collect do |site_element|
      views = @se_totals[site_element.id.to_s].views_between(@date_ranges[2], @date_ranges[3])
      # We get the views and store them in an tuple with the site element
      [views.to_i, site_element]
      # Next we reject any elements without any views, sort by the views, and then
      # distill the results back to just the site elements
    end.reject { |d| d[0] == 0 }.sort_by { |d| d[0] }.reverse!.collect { |d| d[1] }
    # Bail if we don't have any elements with data
    return nil if @sorted_elements.empty?
    # Get the totals for the elements with views
    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @sorted_elements, @site.capabilities.num_days_improve_data)
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
    @end_date = EmailDigestHelper.date_of_previous('Sunday')
    @date_ranges = [@end_date - 13, @end_date - 7, @end_date - 6, @end_date]
  end
end
