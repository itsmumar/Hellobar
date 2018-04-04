class IntercomAnalyticsAdapter
  def track(event:, user:, params:)
    intercom.track(
      event_name: event,
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: params
    )
  end

  delegate :untag_users, :tag_users, to: :intercom

  private

  def intercom
    IntercomGateway.new
  end
end
