# Because Events are used for filtering and messaging,
# and event names are used directly in Intercom by your App's Admins
# we recommend sending high-level activity about your users that you would like to message on,
# rather than raw clickstream or user interface actions.
# For example an order action is a good candidate for an Event,
# versus all the clicks and actions that were taken to get to that point.
# We also recommmend sending event names that combine a past tense verb and nouns,
# such as 'created-bar', 'changed-subscription', etc.
# https://developers.intercom.com/v2.0/reference#events

class AnalyticsProvider
  attr_reader :adapter

  def initialize(adapter)
    @adapter = adapter
  end

  def fire_event(event, **args)
    public_send event.underscore.to_sym, **args
  end

  def auto_renewed_subscription(subscription:, user:)
    site = subscription.site

    track(
      event: 'auto-renewed-subscription',
      user: user,
      params: {
        amount: subscription.amount,
        site_url: site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
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
        identity: contact_list.identity&.provider,
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
        goal: site_element.element_subtype,
        site_url: site_element.site.url
      }
    )
  end

  def changed_subscription(subscription:, user:)
    site = subscription.site

    track(
      event: 'changed-subscription',
      user: user,
      params: {
        amount: subscription.amount,
        site_url: site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  def used_promo_code(site:, coupon:, user:)
    track(
      event: 'used-promo-code',
      user: user,
      params: {
        code: coupon.label,
        trial_days: coupon.trial_period,
        site_url: site.url
      }
    )
  end

  def added_free_days(subscription:, free_days:, user:)
    track(
      event: 'added-free-days',
      user: user,
      params: {
        site_url: subscription.site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        free_days: free_days
      }
    )
  end

  def paid_bill(subscription:, user:)
    site = subscription.site

    track(
      event: 'paid-bill',
      user: user,
      params: {
        amount: subscription.amount,
        site_url: site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  def added_credit_card(user:)
    track(
      event: 'added-credit-card',
      user: user
    )
  end

  def downgraded_site(subscription:, previous_subscription:, user:)
    site = subscription.site

    track(
      event: 'downgraded-site',
      user: user,
      params: {
        site_url: site.url
      }
    )

    tag_users 'Downgraded', site.owners
    tag_users 'Free', site.owners
    untag_users previous_subscription.name, site.owners
    untag_users 'Paid', site.owners
  end

  def used_sender_referral_coupon(subscription:, user:)
    site = subscription.site

    track(
      event: 'used-sender-referral-coupon',
      user: user,
      params: {
        site_url: site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )
  end

  def used_recipient_referral_coupon(subscription:, user:)
    site = subscription.site

    track(
      event: 'used-recipient-referral-coupon',
      user: user,
      params: {
        site_url: site.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
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

  delegate :tag_users, :untag_users, to: :adapter
end
