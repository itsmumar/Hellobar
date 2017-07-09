# Because Events are used for filtering and messaging,
# and event names are used directly in Intercom by your App's Admins
# we recommend sending high-level activity about your users that you would like to message on,
# rather than raw clickstream or user interface actions.
# For example an order action is a good candidate for an Event,
# versus all the clicks and actions that were taken to get to that point.
# We also recommmend sending event names that combine a past tense verb and nouns,
# such as 'created-bar', 'changed-subscription', etc.
# https://developers.intercom.com/v2.0/reference#events
class IntercomAnalytics
  def fire_event(event, **args)
    public_send event, **args
  end

  def site_created(site:, user:)
    track(
      event_name: 'created-site',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { url: site.url }
    )
  end

  def contact_list_created(user:)
    track(
      event_name: 'created-contact-list',
      user_id: user.id,
      created_at: Time.current.to_i
    )
  end

  def site_element_created(site_element:, user:)
    track(
      event_name: 'created-bar',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { bar_type: site_element.type, goal: site_element.element_subtype }
    )
  end

  def subscription_changed(site:)
    subscription = site.current_subscription
    track(
      event_name: 'changed-subscription',
      user_id: site.owners.first.id,
      created_at: Time.current.to_i,
      metadata: { subscription: subscription.name, schedule: subscription.schedule }
    )
    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  private

  def track(options)
    intercom.events.create options
  end

  def tag_users(tag, users)
    intercom.tags.tag(name: tag, users: users.map { |u| { user_id: u.id } })
  end

  def intercom
    @intercom ||= Intercom::Client.new(token: Settings.intercom_token)
  end
end
