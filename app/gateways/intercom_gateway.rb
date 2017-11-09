class IntercomGateway
  def track opts
    client.events.create opts
  end

  def create_user user
    client.users.create(user_id: user.id, email: user.email)
  end

  def tag_users tag, users
    return if users.blank? || tag.blank?

    client.tags.tag(name: tag, users: users.map { |u| { user_id: u.id } })
  end

  def find_user user_id
    client.users.find user_id: user_id
  rescue Intercom::ResourceNotFound
    nil
  end

  def delete_user user_id
    intercom_user = find_user user_id

    return unless intercom_user

    client.users.delete intercom_user
  end

  private

  def client
    @client ||= Intercom::Client.new initialization_opts
  end

  def initialization_opts
    {
      token: Settings.intercom_token,
      handle_rate_limit: true
    }
  end
end
