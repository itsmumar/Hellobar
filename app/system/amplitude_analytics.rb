class AmplitudeAnalytics
  def fire_event(event, **args)
    public_send event.underscore.to_sym, **args
  end

  def created_user(user:)
    track user
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
      metadata: { site_url: site.url }
    )
  end

  def created_site(site:, user:)
    track(
      event_type: 'created-site',
      user_id: user.id,
      metadata: { url: site.url }
    )
  end

  def installed_script(site:, user:)
    track(
      event_type: 'installed-script',
      user_id: user.id,
      metadata: { url: site.url }
    )
  end

  def uninstalled_script(site:, user:)
    track(
      event_type: 'uninstalled-script',
      user_id: user.id,
      metadata: { url: site.url }
    )
  end

  def created_contact_list(contact_list:, user:)
    track(
      event_type: 'created-contact-list',
      user_id: user.id,
      metadata: { site_url: contact_list.site.url }
    )
  end

  def created_bar(site_element:, user:)
    track(
      event_type: 'created-bar',
      user_id: user.id,
      metadata: { bar_type: site_element.type, goal: site_element.element_subtype }
    )
  end

  def changed_subscription(site:, user:)
    subscription = site.current_subscription || Subscription::Free.new

    track(
      event_type: 'changed-subscription',
      user_id: user.id,
      metadata: { subscription: subscription.name, schedule: subscription.schedule }
    )
  end

  private

  def track(params)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(params))
    AmplitudeAPI.track(event)
  end
end
