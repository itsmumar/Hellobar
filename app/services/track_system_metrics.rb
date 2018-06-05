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
      active_sites: active_sites,
      active_users: active_users,
      active_site_elements: active_site_elements,
      active_paid_subscriptions: active_paid_subscriptions,
      paying_users: paying_users,
      pending_bills_sum: pending_bills_sum
    }
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

  def paying_users
    User
      .joins(credit_cards: { billing_attempts: { bill: :subscription } })
      .merge(Subscription.paid.merge(Bill.non_free))
      .count
  end

  def pending_bills_sum
    Bill.pending.sum(:amount)
  end

  def send_event(attributes)
    event = AmplitudeAPI::Event.new({ time: Time.current }.merge(attributes))
    AmplitudeAPI.track(event)
  end
end
