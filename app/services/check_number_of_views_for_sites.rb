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
    warning_level = site.warning_level_one

    if number_of_views > limit
      handle_overage_site(site, number_of_views, limit)
    elsif
      send_warning_email(site, number_of_views, limit)
    end
  end

  def handle_overage_site(site, number_of_views, limit)
    report.limit_exceeded(site, number_of_views, limit)
    HandleOverageSiteJob.perform_later(site, number_of_views, limit)
  end

  def send_warning_email(site, number_of_views, limit)
    # send the warning email
    
  end
end
