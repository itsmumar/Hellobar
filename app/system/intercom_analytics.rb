class IntercomAnalytics
  def self.event(name, **options)
    new.public_send(name, **options)
  end

  def subscription_changed(site:)
    site.owners.each do |user|
      track event_name: 'changed-subscription',
        user_id: user.id,
        created_at: Time.current.to_i,
        metadata: { subscription: site.current_subscription.name, schedule: site.current_subscription.schedule }
    end
    tag_users 'Paid', site.owners unless site.current_subscription.amount.zero?
    tag_users site.current_subscription.name, site.owners
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
