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
    public_send event.underscore.to_sym, **args
  end

  def created_user(user:)
    intercom.users.create(user_id: user.id, email: user.email)
  end

  def signed_up(user:)
    track(
      event_name: 'signed-up',
      user_id: user.id,
      created_at: Time.current.to_i
    )
  end

  def invited_member(site:, user:)
    track(
      event_name: 'invited-member',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { site_url: site.url }
    )
  end

  def created_site(site:, user:)
    track(
      event_name: 'created-site',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { url: site.url }
    )
  end

  def installed_script(site:, user:)
    track(
      event_name: 'installed-script',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { url: site.url }
    )
  end

  def uninstalled_script(site:, user:)
    track(
      event_name: 'uninstalled-script',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { url: site.url }
    )
  end

  def created_contact_list(contact_list:, user:)
    track(
      event_name: 'created-contact-list',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { site_url: contact_list.site.url }
    )
  end

  def created_bar(site_element:, user:)
    track(
      event_name: 'created-bar',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { bar_type: site_element.type, goal: site_element.element_subtype }
    )
  end

  def changed_subscription(site:, user:)
    subscription = site.current_subscription
    track(
      event_name: 'changed-subscription',
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: { subscription: subscription.name, schedule: subscription.schedule }
    )
    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  private

  delegate :track, :tag_users, to: :intercom

  def intercom
    IntercomGateway.new
  end
end
