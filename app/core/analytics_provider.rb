class AnalyticsProvider
  attr_reader :adapter

  def initialize(adapter)
    @adapter = adapter
  end

  def fire_event(event, **args)
    public_send event.underscore.to_sym, **args
  end

  def signed_up(user:)
    track(
      event: 'signed-up',
      user: user
    )
  end

  def invited_member(site:, user:)
    track(
      event: 'invited-member',
      user: user,
      params: {
        site_url: site.url
      }
    )
  end

  def created_site(site:, user:)
    track(
      event: 'created-site',
      user: user,
      params: {
        url: site.url
      }
    )
  end

  def installed_script(site:, user:)
    track(
      event: 'installed-script',
      user: user,
      params: {
        url: site.url
      }
    )
  end

  def uninstalled_script(site:, user:)
    track(
      event: 'uninstalled-script',
      user: user,
      params: {
        url: site.url
      }
    )
  end

  def created_contact_list(contact_list:, user:)
    track(
      event: 'created-contact-list',
      user: user,
      params: {
        site_url: contact_list.site.url
      }
    )
  end

  def created_bar(site_element:, user:)
    track(
      event: 'created-bar',
      user: user,
      params: {
        bar_type: site_element.type,
        goal: site_element.element_subtype
      }
    )
  end

  def changed_subscription(site:, user:)
    subscription = site.current_subscription || Subscription::Free.new

    track(
      event: 'changed-subscription',
      user: user,
      params: {
        subscription: subscription.name,
        schedule: subscription.schedule
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  def used_promo_code(code:, user:)
    track(
      event: 'used-promo-code',
      user: user,
      params: {
        code: code
      }
    )
  end

  private

  def track(event:, user:, params: {})
    adapter.track(
      event: event,
      user: user,
      params: params
    )
  end

  delegate :tag_users, to: :adapter
end
