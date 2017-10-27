class IntercomGateway
  def track opts
    intercom.events.create opts
  end

  def create_user user
    intercom.users.create(user_id: user.id, email: user.email)
  end

  def tag_users tag, users
    return if users.blank?

    intercom.tags.tag(name: tag, users: users.map { |u| { user_id: u.id } })
  end

  private

  def intercom
    @intercom ||= Intercom::Client.new initialization_opts
  end

  def initialization_opts
    {
      token: Settings.intercom_token,
      handle_rate_limit: true
    }
  end
end
