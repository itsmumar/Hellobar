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
    when Subscription::Elite::Capabilities
      handle_elite
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

  def handle_elite
    update_elite_overage_count
  end

  def update_elite_overage_count
    delta = (@number_of_views - @limit)
    current_charge_count = @site.overage_count
    new_charge_count = (delta.to_f / 100_000.0).ceil

    return unless new_charge_count > current_charge_count
    site.update(limit_email_sent: true)
    OveragePaidMailer.overage_email(site, number_of_views, limit).deliver_later
    @site.update(overage_count: new_charge_count)
  end

  def handle_pro_managed
  end

  def handle_pro_comped
  end

  def handle_growth
    return if @site.current_subscription.currently_on_trial? # let users on free trials go nuts until the trial is over
    update_growth_overage_count
  end

  def update_growth_overage_count
    delta = (@number_of_views - @limit)
    current_charge_count = @site.overage_count
    new_charge_count = (delta.to_f / 25_000.0).ceil

    return unless new_charge_count > current_charge_count
    @site.update(overage_count: new_charge_count)
    site.update(limit_email_sent: true)
    OveragePaidMailer.overage_email(site, number_of_views, limit).deliver_later
  end

  def handle_pro
    update_growth_overage_count # pro is the same as growth now
  end

  def handle_free_plus
  end

  def handle_free
    @site.deactivate_site_element

    return unless site.limit_email_sent == false
    site.update(limit_email_sent: true)
    OverageFreeMailer.overage_email(site, number_of_views, limit).deliver_later
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
