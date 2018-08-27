class HandleOverageSite
  class UnknownSubscriptionError < StandardError
  end

  def initialize(site, number_of_views, limit)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
  end

  def call
    handle_site
  end

  private

  attr_reader :site, :number_of_views, :limit

  def handle_site
    track_exceeded_views_limit_event
    handle_subscription_specific_case
  end

  def handle_subscription_specific_case
    case site.capabilities
    when Subscription::Enterprise::Capabilities
      handle_enterprise
    when Subscription::ProManaged::Capabilities
      handle_pro_managed
    when Subscription::ProComped::Capabilities
      handle_pro_comped
    when Subscription::Growth::Capabilities
      handle_growth
    when Subscription::Pro::Capabilities
      handle_pro
    when Subscription::FreePlus::Capabilities
      handle_free_plus
    when Subscription::Free::Capabilities
      handle_free
    else
      raise UnknownSubscriptionError, site.capabilities.class.name
    end
  end

  def handle_enterprise
    # OveragePaidMailer.overage_email(site, number_of_views, limit).deliver_later
  end

  def handle_pro_managed
  end

  def handle_pro_comped
  end

  def handle_growth
    # OveragePaidMailer.overage_email(site, number_of_views, limit).deliver_later
  end

  def handle_pro
    # OveragePaidMailer.overage_email(site, number_of_views, limit).deliver_later
  end

  def handle_free_plus
  end

  def handle_free
    # OverageFreeMailer.overage_email(site, number_of_views, limit).deliver_later
  end

  def track_exceeded_views_limit_event
    TrackEvent.new(
      :exceeded_views_limit,
      user: site.owners.first,
      site: site,
      number_of_views: number_of_views,
      limit: limit
    ).call
  end
end
