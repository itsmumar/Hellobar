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
    setup_views_counter(site, number_of_views)
    if number_of_views > @limit
      handle_overage_site(site, number_of_views, @limit)
    elsif number_of_views < @limit && number_of_views > @warning_level_one && site.warning_email_one_sent == false
      send_warning_email(site, number_of_views, @limit, @warning_level_one, 'warning_email_one_sent')
    elsif number_of_views < @limit && number_of_views > @warning_level_two && site.warning_email_two_sent == false && site.free?
      send_warning_email(site, number_of_views, @limit, @warning_level_two, 'warning_email_two_sent')
    elsif number_of_views < @limit && number_of_views > @warning_level_three && site.warning_email_three_sent == false && site.free?
      send_warning_email(site, number_of_views, @limit, @warning_level_three, 'warning_email_three_sent')
    end
  end

  def setup_views_counter(site, number_of_views)
    subscription = site.active_subscription
    last_bill = subscription.bills.where(status: 'paid').last if subscription

    report.count(number_of_views)

    # the following if / elsif is a temporary handling of existing elite annual subscriptions where the user signed up before we had view limits
    if subscription && last_bill && subscription.schedule == 'yearly' && subscription.type == 'Subscription::Elite' && last_bill.bill_at < Subscription::GRANDFATHER_VIEW_LIMIT_EFFECTIVE_DATE
      @limit = ::Float::INFINITY
      @warning_level_one = ::Float::INFINITY
      @warning_level_two = ::Float::INFINITY
      @warning_level_three = ::Float::INFINITY
      # report.log_grandfathered_site(site)
    elsif subscription && last_bill && subscription.schedule == 'yearly' && (subscription.type == 'Subscription::Growth' || subscription.type == 'Subscription::Pro') && last_bill.bill_at < Subscription::GRANDFATHER_VIEW_LIMIT_EFFECTIVE_DATE
      @limit = 250_000
      @warning_level_one = 200_000
      @warning_level_two = ::Float::INFINITY
      @warning_level_three = ::Float::INFINITY
      # report.log_grandfathered_site(site)
    else
      @limit = site.views_limit
      @warning_level_one = site.visit_warning_one
      @warning_level_two = site.visit_warning_two
      @warning_level_three = site.visit_warning_three
    end
  end

  def handle_overage_site(site, number_of_views, limit)
    report.limit_exceeded(site, number_of_views, limit)
    HandleOverageSiteJob.perform_later(site, number_of_views, limit)
    subscription = site.active_subscription

    if number_of_views >= site.upsell_email_trigger && site.upsell_email_sent == false && subscription.is_a?(Subscription::Elite)
      site.update(upsell_email_sent: true)
      report.send_elite_upsell_email(site, number_of_views, limit)
    elsif number_of_views >= site.upsell_email_trigger && site.upsell_email_sent == false && !subscription.is_a?(Subscription::Elite)
      site.update(upsell_email_sent: true)
      report.send_upsell_email(site, number_of_views, limit)
    end
  end

  def send_warning_email(site, number_of_views, limit, warning_level, db_field)
    site.update_column(db_field, true)
    report.send_warning_email(site, number_of_views, limit, warning_level)
  end
end
