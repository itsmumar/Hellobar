class AmplitudeAnalyticsAdapter
  def track(event:, user:, params:)
    send_event(
      event_type: event,
      user_id: user.id,
      event_properties: params,
      user_properties: user_properties(user)
    )
  end

  def tag_users(*)
    # do nothing
  end

  def untag_users(*)
    # do nothing
  end

  private

  def send_event(attributes)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(attributes))
    AmplitudeAPI.track(event)
  end

  def domains_for(user)
    user.sites.map { |site| NormalizeURI[site.url]&.domain }.compact
  end

  def user_properties(user)
    primary_domain, *additional_domains = domains_for(user)

    {
      primary_domain: primary_domain,
      additional_domains: additional_domains.join(', '),
      contact_lists: user.contact_lists.count,
      total_views: user.sites.map { |site| site.statistics.views }.sum,
      total_conversions: user.sites.map { |site| site.statistics.conversions }.sum,
      total_subscribers: user.sites.map { |site| total_subscribers(site) }.sum,
      sites_count: user.sites.count,
      site_elements_count: user.site_elements.count,
      managed_sites: user.site_ids
    }
  end

  def total_subscribers(site)
    FetchSiteContactListTotals.new(site).call.values.sum
  end
end
