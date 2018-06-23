class TrackSystemMetrics
  EVENT = 'system'.freeze
  DEVICE_ID = 'hello-bar'.freeze

  def call
    return unless Rails.env.production?

    send_event(
      event_type: EVENT,
      device_id: DEVICE_ID,
      event_properties: event_properties
    )
  end

  private

  def event_properties
    {
      installed_sites: installed_sites,
      active_sites: active_sites,
      active_users: active_users,
      active_site_elements: active_site_elements,
      active_paid_subscriptions: active_paid_subscriptions,
      active_paid_pro_subscriptions: active_paid_pro_subscriptions,
      active_paid_growth_subscriptions: active_paid_growth_subscriptions,
      active_paid_enterprise_subscriptions: active_paid_enterprise_subscriptions,
      active_paid_subscription_average_days: active_paid_subscription_average_days,
      paying_users: paying_users,
      paying_pro_users: paying_pro_users,
      paying_growth_users: paying_growth_users,
      paying_enterprise_users: paying_enterprise_users,
      pending_bills_sum: pending_bills_sum,
      failed_bills_sum: failed_bills_sum,
      future_voided_bills_sum: future_voided_bills_sum,
      last_month_voided_bills_sum: last_month_voided_bills_sum
    }
  end

  def installed_sites
    Site.script_installed.count
  end

  def active_sites
    Site.active.count
  end

  def active_users
    User.joins(:sites).merge(Site.active).count
  end

  def active_site_elements
    SiteElement.joins(rule: :site).merge(Site.active).count
  end

  def active_paid_subscriptions
    Subscription.paid.merge(Bill.non_free).count
  end

  def active_paid_pro_subscriptions
    Subscription.paid.pro.merge(Bill.non_free).count
  end

  def active_paid_growth_subscriptions
    Subscription.paid.growth.merge(Bill.non_free).count
  end

  def active_paid_enterprise_subscriptions
    Subscription.paid.enterprise.merge(Bill.non_free).count
  end

  def active_paid_subscription_average_days
    average_timestamp =
      Subscription
      .paid
      .merge(Bill.non_free)
      .average('UNIX_TIMESTAMP(subscriptions.created_at)').to_i

    (Time.current.to_i - average_timestamp) / 1.day.to_f
  end

  def paying_users
    paying_users_query.count
  end

  def paying_pro_users
    paying_users_query.merge(Subscription.pro).count
  end

  def paying_growth_users
    paying_users_query.merge(Subscription.growth).count
  end

  def paying_enterprise_users
    paying_users_query.merge(Subscription.enterprise).count
  end

  def paying_users_query
    User
      .joins(credit_cards: { billing_attempts: { bill: :subscription } })
      .merge(Subscription.paid.merge(Bill.non_free))
  end

  def pending_bills_sum
    Bill.pending.sum(:amount)
  end

  def failed_bills_sum
    Bill.failed.sum(:amount)
  end

  def future_voided_bills_sum
    Bill.voided.where('bills.bill_at > ?', Time.current).sum(:amount)
  end

  def last_month_voided_bills_sum
    Bill.voided.where(status_set_at: 1.month.ago..Time.current).sum(:amount)
  end

  def send_event(attributes)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(attributes))
    AmplitudeAPI.track(event)
  end
end
