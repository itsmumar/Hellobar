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
    params = {}

    # Affiliate signups additional params
    if user.affiliate_identifier
      params[:affiliate_identifier] = user.affiliate_identifier
      params[:source] = 'affiliate'

      partner = user.affiliate_information&.partner
      partner_plan = partner&.partner_plan

      if partner_plan
        params[:trial_period] = partner_plan.duration
        params[:trial_subscription] = partner_plan.subscription_type
        params[:credit_card_signup] = partner.require_credit_card
      end
    end

    # Promotional signups additional params
    if promotional_signup?(user)
      plan = PromotionalPlan.new

      params[:promotional_identifier] = user.utm_source if user.utm_source.present?
      params[:source] = user.source
      params[:trial_period] = plan.duration
      params[:trial_subscription] = plan.subscription_type
      params[:credit_card_signup] = false
    end

    track(
      event: 'signed-up',
      user: user,
      params: params
    )

    tag_users('Affiliate', [user]) if user.affiliate_identifier
    tag_users('Promotional', [user]) if promotional_signup?(user)
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
    return if !contact_list || contact_list.deleted?

    track(
      event: 'created-contact-list',
      user: user,
      params: {
        identity: contact_list.identity&.provider,
        site_url: contact_list.site&.url
      }
    )
  end

  def created_bar(site_element:, user:)
    return if !site_element || site_element.deleted?

    track(
      event: 'created-bar',
      user: user,
      params: {
        bar_type: site_element.type,
        goal: site_element.element_subtype,
        site_url: site_element.site&.url
      }
    )
  end

  def upgraded_subscription(params)
    changed_subscription('upgraded-subscription', params)
  end

  def downgraded_subscription(params)
    changed_subscription('downgraded-subscription', params)
  end

  def granted_free_days(subscription:, free_days:, user:)
    track(
      event: 'granted-free-days',
      user: user,
      params: {
        site_url: subscription.site&.url,
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
        site_url: site&.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
  end

  def added_credit_card(user:, site:)
    subscription = site.current_subscription || Subscription::Free.new

    track(
      event: 'added-credit-card',
      user: user,
      params: {
        site_url: site&.url,
        subscription: subscription.name,
        schedule: subscription.schedule
      }
    )
  end

  def used_sender_referral_coupon(subscription:, user:)
    site = subscription.site

    track(
      event: 'used-sender-referral-coupon',
      user: user,
      params: {
        site_url: site&.url,
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
        site_url: site&.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0
      }
    )
  end

  def referred_friend(referral:, user:)
    track(
      event: 'referred-friend',
      user: user,
      params: {
        email: referral.email,
        site_url: referral.site&.url
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

  def changed_subscription(event, subscription:, previous_subscription:, user:)
    site = Site.with_deleted.find(subscription.site_id)

    track(
      event: event,
      user: user,
      params: {
        amount: subscription.amount,
        site_url: site&.url,
        subscription: subscription.name,
        schedule: subscription.schedule,
        trial_days: subscription.trial_period || 0,
        previous_subscription: previous_subscription&.name,
        previous_subscription_amount: previous_subscription&.amount,
        previous_subscription_schedule: previous_subscription&.schedule
      }
    )

    tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners

    return unless previous_subscription

    untag_users previous_subscription.name, site.owners
    untag_users 'Paid', site.owners if subscription.amount.zero?
  end

  def promotional_signup? user
    user.source == 'promotional'
  end
end
