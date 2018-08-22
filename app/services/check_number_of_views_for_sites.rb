class CheckNumberOfViewsForSites
  BATCH_SIZE = 100

  def initialize(sites = Site.active)
    @sites = sites
    @report = BillingViewsReport.new(sites.count)
  end

  def call
    report.start
    process
    report.finish
  rescue Exception => e # rubocop: disable Lint/RescueException
    # handle `kill` or `Ctrl + C`
    Raven.capture_exception(e)
    report.interrupt(e)
    raise
  end

  private

  attr_reader :report, :sites

  def process
    sites.find_in_batches(batch_size: BATCH_SIZE) do |sites|
      check_views_number_for_sites(sites)
    end
  end

  def check_views_number_for_sites(sites)
    number_of_views_for_current_month = FetchTotalViewsForMonth.new(sites).call

    sites.each do |site|
      check_views_number_for_site site, number_of_views_for_current_month[site.id]
    end
  end

  def check_views_number_for_site(site, number_of_views)
    report.count(number_of_views)
    limit = site.views_limit
    warning_level_one = site.visit_warning_one
    warning_level_two = site.visit_warning_two
    warning_level_three = site.visit_warning_three

    if number_of_views > limit
      handle_overage_site(site, number_of_views, limit)

    elsif number of views < limit && number_of_views > warning_level_one && site.warning_email_one_sent == false
      send_warning_email(site, number_of_views, limit, warning_level_one, 'warning_email_one_sent')
    elsif number of views < limit && number_of_views > warning_level_two && site.warning_email_two_sent == false && site.free?
      send_warning_email(site, number_of_views, limit, warning_level_two, 'warning_email_two_sent')
    elsif number of views < limit && number_of_views > warning_level_three && site.warning_email_three_sent == false && site.free?
      send_warning_email(site, number_of_views, limit, warning_level_three, 'warning_email_three_sent')
    end
  end

  def handle_overage_site(site, number_of_views, limit)
    report.limit_exceeded(site, number_of_views, limit)
    HandleOverageSiteJob.perform_later(site, number_of_views, limit)
  end

  def send_warning_email(site, number_of_views, limit, warning_level, db_field)
    site.update("#{db_field}": true)
    report.send_warning_email(site, number_of_views, limit, warning_level)
  end
end
