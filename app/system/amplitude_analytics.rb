class AmplitudeAnalytics
  def fire_event(event, **args)
    public_send event.underscore.to_sym, **args
  end

  def signed_up(user:)
    track(
      event_type: 'signed-up',
      user_id: user.id
    )
  end

  def invited_member(site:, user:)
    track(
      event_type: 'invited-member',
      user_id: user.id,
      event_properties: {
        site_url: site.url,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def created_site(site:, user:)
    track(
      event_type: 'created-site',
      user_id: user.id,
      event_properties: {
        url: site.url,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def installed_script(site:, user:)
    track(
      event_type: 'installed-script',
      user_id: user.id,
      event_properties: {
        url: site.url,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def uninstalled_script(site:, user:)
    track(
      event_type: 'uninstalled-script',
      user_id: user.id,
      event_properties: {
        url: site.url,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def created_contact_list(contact_list:, user:)
    track(
      event_type: 'created-contact-list',
      user_id: user.id,
      event_properties: {
        site_url: contact_list.site.url,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def created_bar(site_element:, user:)
    track(
      event_type: 'created-bar',
      user_id: user.id,
      event_properties: {
        bar_type: site_element.type,
        goal: site_element.element_subtype,
        current_subscription: site.current_subscription&.name
      },
      user_properties: user_properties(user)
    )
  end

  def changed_subscription(site:, user:)
    subscription = site.current_subscription || Subscription::Free.new

    track(
      event_type: 'changed-subscription',
      user_id: user.id,
      event_properties: {
        subscription: subscription.name,
        schedule: subscription.schedule
      },
      user_properties: user_properties(user)
    )
  end

  private

  def track(params)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(params))
    AmplitudeAPI.track(event)
  end

  def user_properties user
    {
      additional_domains: user.sites.map { |site| NormalizeURI[site.url]&.domain }.compact.join(', '),
      contact_lists: user.contact_lists.count,
      total_views: user.sites.map { |site| site.statistics.views }.sum,
      total_conversions: user.sites.map { |site| site.statistics.conversions }.sum,
      sites_count: user.sites.count,
      site_elements_count: user.site_elements.count
    }
  end
end
