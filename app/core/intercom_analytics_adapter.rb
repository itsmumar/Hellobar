class IntercomAnalyticsAdapter
  USER_NOT_FOUND = 'User Not Found'.freeze

  def track(event:, user:, params:)
    intercom.track(
      event_name: event,
      user_id: user.id,
      created_at: Time.current.to_i,
      metadata: params
    )
  end

  def untag_users(tag, users)
    intercom.untag_users tag, users
  rescue Intercom::ResourceNotFound => e
    raise e unless e.message == IntercomAnalyticsAdapter::USER_NOT_FOUND
    insure_users_existing(users)

    intercom.untag_users tag, users
  end

  def tag_users(tag, users)
    intercom.tag_users tag, users
  rescue Intercom::ResourceNotFound => e
    raise e unless e.message == IntercomAnalyticsAdapter::USER_NOT_FOUND
    insure_users_existing(users)

    intercom.tag_users tag, users
  end

  private

  def insure_users_existing(users)
    users.each { |user| intercom.create_user user }
  end

  def intercom
    @intercom ||= IntercomGateway.new
  end
end
