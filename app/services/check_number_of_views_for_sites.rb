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

    report.limit_exceeded(site, number_of_views, limit) if number_of_views > limit
  end
end
