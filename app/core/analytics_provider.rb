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

  def signed_up(user:, promotional_signup: false, utm_source: nil, credit_card_signup: false)
    params = { admin_link: "https://app.hellobar.com/admin/users/#{ user.id }" }

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
      tag_users('Affiliate', [user])

      # Promotional signups additional params
    elsif promotional_signup
      plan = PromotionalPlan.new

      params[:promotional_identifier] = utm_source if utm_source.present?
      params[:source] = 'promotional'
      params[:trial_period] = plan.duration
      params[:trial_subscription] = plan.subscription_type
      params[:credit_card_signup] = credit_card_signup

      tag_users('Promotional', [user])
    end

    track(
      event: 'signed-up',
      user: user,
      params: params
    )
    tag_users('Free', [user])

    update_user(user: user, params: params) if user.affiliate_identifier || promotional_signup
  end

  def invited_member(site:, user:)
    track(
      event: 'invited-member',
      user: user,
      params: {
        site_url: site.url,
        site_id: site.id
      }
    )
  end

  def created_site(site:, user:)
    params = {
      url: site.url,
      site_id: site.id
    }

    track(
      event: 'created-site',
      user: user,
      params: params
    )
    tag_users "#{ user.sites.count } Sites", site.owners
    untag_users "#{ (user.sites.count - 1) } Sites", site.owners unless user.sites.count == 1
    update_user(user: user, params: params)
  end

  def installed_script(site:, user:)
    track(
      event: 'installed-script',
      user: user,
      params: {
        url: site.url,
        site_id: site.id,
        install_type: site.install_type
      }
    )
    tag_users site.install_type, site.owners
  end

  def uninstalled_script(site:, user:)
    track(
      event: 'uninstalled-script',
      user: user,
      params: {
        url: site.url,
        site_id: site.id
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
        site_url: contact_list.site&.url,
        site_id: contact_list.site&.id
      }
    )
  end

  def created_bar(site_element:, user:)
    site = site_element.site
    if site_element.type == 'Bar'
      created_element('created_bar', site, site_element, user)
    elsif site_element.type == 'Modal'
      created_element('created_modal', site, site_element, user)
    elsif site_element.type == 'Slider'
      created_element('created_slider', site, site_element, user)
    elsif site_element.type == 'Takeover'
      created_element('created_page_takeover', site, site_element, user)
    elsif site_element.type == 'Alert'
      created_element('created_alert', site, site_element, user)
    end
  end

  def updated_bar(site_element:, user:)
    site = site_element.site
    if site_element.type == 'Bar'
      updated_element('updated_bar', site, site_element, user)
    elsif site_element.type == 'Modal'
      updated_element('updated_modal', site, site_element, user)
    elsif site_element.type == 'Slider'
      updated_element('updated_slider', site, site_element, user)
    elsif site_element.type == 'Takeover'
      updated_element('updated_page_takeover', site, site_element, user)
    elsif site_element.type == 'Alert'
      updated_element('updated_alert', site, site_element, user)
    end
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
    subscription = site&.current_subscription || Subscription::Free.new

    track(
      event: 'added-credit-card',
      user: user,
      params: {
        site_url: site&.url,
        site_id: site&.id,
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

  def exceeded_views_limit(site:, user:, limit:, number_of_views:)
    subscription = site.current_subscription || Subscription::Free.new
    params = {}
    params[:site_id] = site.id
    params[:site_url] = site.url
    params[:number_of_views] = number_of_views
    params[:limit] = limit
    params[:subscription] = subscription.name
    params[:schedule] = subscription.schedule
    params[:overage_count] = site.overage_count
    params[:visit_overage] = subscription.visit_overage
    params[:overage_fees] = subscription.overage_count * 5 unless subscription.free?
    params[:upgrade_link] = "https://app.hellobar.com/sites/#{ site.id }/edit"

    track(
      event: 'exceeded-views-limit',
      user: user,
      params: params
    )
    update_user(user: user, params: params)
  end

  def updated_site_count(user:)
    # clean up possibly stale tags
    untag_users "#{ (user.sites.count - 1) } Sites", [user] if user.sites.count > 1
    untag_users "#{ user.sites.count } Sites", [user]
    untag_users "#{ (user.sites.count + 1) } Sites", [user]
    untag_users 'Multiple Sites', [user]

    # tag with current count
    tag_users "#{ user.sites.count } Sites", [user]
    tag_users 'Multiple Sites', [user] if user.sites.count > 1
  end

  def added_dme(user:, highest_subscription_name:)
    track(
      event: 'add-dme',
      user: user,
      params: {}
    )

    tag_users 'DME', [user]
    tag_users highest_subscription_name, [user]
  end

  def free_overage(user:, site:)
    params = {
      site_id: site.id,
      site_url: site.url,
      limit: 5000,
      overage_count: site.overage_count
    }

    track(
      event: 'free-overage',
      user: user,
      params: params
    )
    update_user(user: user, params: params)
  end

  def triggered_upgrade_account(user:, source:)
    params = {
      source: source
    }

    track(
      event: 'triggered-upgrade-account',
      user: user,
      params: params
    )
    update_user(user: user, params: params)
  end

  def triggered_payment_checkout(user:, source:)
    track(
      event: 'triggered-payment-checkout',
      user: user,
      params: {
        source: source
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

  delegate :tag_users, :untag_users, :update_user, to: :adapter

  def changed_subscription(event, subscription:, previous_subscription:, user:)
    site = Site.with_deleted.find(subscription.site_id)
    params = {
      amount: subscription.amount,
      site_url: site&.url,
      site_id: site&.id,
      subscription: subscription.name,
      schedule: subscription.schedule,
      trial_days: subscription.trial_period || 0,
      previous_subscription: previous_subscription&.name,
      previous_subscription_amount: previous_subscription&.amount,
      previous_subscription_schedule: previous_subscription&.schedule,
      subscription_start_date: subscription.created_at
    }

    track(
      event: event,
      user: user,
      params: params
    )

    # tag_users 'Paid', site.owners unless subscription.amount.zero?
    tag_users subscription.name, site.owners
    update_user(user: user, params: params)

    return unless previous_subscription

    untag_users previous_subscription.name, site.owners
    # untag_users 'Paid', site.owners if subscription.amount.zero?
  end

  def created_element(event, site, site_element, user)
    track(
      event: event,
      user: user,
      params: {
        goal: site_element.element_subtype,
        type: site_element.type,
        theme_id: site_element.theme_id,
        enable_gdpr: site_element.enable_gdpr,
        show_branding: site_element.show_branding,
        headline: site_element.headline,
        use_default_image: site_element.use_default_image,
        link_text: site_element.link_text,
        use_question: site_element.use_question,
        site_url: site.url,
        site_id: site.id
      }
    )
  end

  def updated_element(event, site, site_element, user)
    track(
      event: event,
      user: user,
      params: {
        goal: site_element.element_subtype,
        type: site_element.type,
        theme_id: site_element.theme_id,
        enable_gdpr: site_element.enable_gdpr,
        show_branding: site_element.show_branding,
        headline: site_element.headline,
        use_default_image: site_element.use_default_image,
        link_text: site_element.link_text,
        use_question: site_element.use_question,
        site_url: site.url,
        site_id: site.id
      }
    )
  end
end
