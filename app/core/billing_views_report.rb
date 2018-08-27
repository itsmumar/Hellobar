class BillingViewsReport
  include ActionView::Helpers::NumberHelper

  attr_reader :log

  def initialize(sites_count)
    @log = []
    @sites_count = sites_count
    @count = 0
    @total_views = 0
    @overage_views = 0
    @overage_views_paid_sites = 0
  end

  def start
    info "#{ Rails.env }: #{ Time.current }"
    info '-' * 80
    info "Found *#{ number_with_delimiter(@sites_count) }* active sites..."
  end

  def finish
    info '-' * 80
    info "*#{ number_with_delimiter(@count) }* sites have been processed"
    info "*#{ number_with_delimiter(@total_views) }* total views"
    info "*#{ number_with_delimiter(@overage_views) }* overage views total"
    info "*#{ number_with_delimiter(@overage_views_paid_sites) }* overage views on paid plans"
    info "#{ Rails.env }: #{ Time.current }"
    info ''
    info ''
  end

  def interrupt(e)
    info '---- INTERRUPT ----'
    info e.inspect if e
    finish
  end

  def count(number_of_views)
    @count += 1
    @total_views += number_of_views
    info "#{ @count } sites processed..." if !@count.zero? && @count % 500 == 0
  end

  def limit_exceeded(site, number_of_views, limit)
    delta = number_of_views - limit
    @overage_views += delta
    @overage_views_paid_sites += delta unless site.free?
    numbers = "#{ number_with_delimiter(number_of_views) }/#{ number_with_delimiter(limit) }"
    info "Limit exceeded #{ site.id } #{ site.url } -- #{ numbers } (*#{ number_with_delimiter(delta) }*) views"
  end

  def send_warning_email(site, number_of_views, limit, warning_level)
    # WarningMailer.warning_email(site, number_of_views, limit, warning_level).deliver_later
  end

  private

  def info(msg)
    log << msg
    post_to_slack msg if Settings.slack_channels['billing'].present?
    BillingLogger.info msg
    puts msg # rubocop:disable Rails/Output
  end

  def post_to_slack(msg)
    PostToSlack.new(:billing, text: msg).call
  rescue StandardError
    nil
  end
end
