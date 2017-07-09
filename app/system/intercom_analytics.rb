class IntercomAnalytics
  def fire_event(event, **args)
    public_send event, **args
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
