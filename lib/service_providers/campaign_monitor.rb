class ServiceProviders::CampaignMonitor < ServiceProviders::Email
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(provider: 'createsend').first
      raise 'Site does not have a stored Campaign Monitor identity' unless identity
    end

    @identity = identity
    initialize_client(identity)
  end

  def lists
    handle_error do
      @client.clients.map do |cl|
        client = CreateSend::Client.new(@auth, cl.ClientID)
        client.lists.map { |l| { 'id' => l['ListID'], 'name' => l['Name'] } }
      end.flatten
    end
  end

  def subscribe(list_id, email, name = nil, _double_optin = true)
    handle_error do
      CreateSend::Subscriber.add(@auth, list_id, email, name, [], true, true)
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, _double_optin = true)
    handle_error do
      subscribers = subscribers.map { |s| { 'EmailAddress' => s[:email], 'Name' => s[:name] } }
      CreateSend::Subscriber.import(@auth, list_id, subscribers, true, true)
    end
  end

  private

  def handle_error(retries = 2)
    yield
  rescue CreateSend::ExpiredOAuthToken => e
    if @client
      identity.credentials['token'], identity.credentials['expires_at'], identity.credentials['refresh_token'] = @client.refresh_token
      identity.save
      retry unless (retries -= 1).zero?
    end
    identity.destroy_and_notify_user if identity != nil
    raise e
  rescue CreateSend::RevokedOAuthToken => e
    identity.destroy_and_notify_user if identity != nil
    raise e
  end

  def initialize_client(identity)
    handle_error do
      @auth = {
        access_token: identity.credentials['token'],
        refresh_token: identity.credentials['refresh_token']
      }

      @client = CreateSend::CreateSend.new(@auth)
    end
  end
end
