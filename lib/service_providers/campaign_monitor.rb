class ServiceProviders::CampaignMonitor < ServiceProvider
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'createsend').first
      raise "Site does not have a stored Campaign Monitor identity" unless identity
    end

    initialize_client(identity)
  end

  def lists
    @client.lists.map{|l| {'id' => l['ListID'], 'name' => l['Name']}}
  end

  def subscribe(list_id, email, name = nil)
    CreateSend::Subscriber.add(@auth, list_id, email, name, [], true)
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    subscribers = subscribers.map{|s| {'EmailAddress' => s[:email], 'Name' => s[:name]}}
    CreateSend::Subscriber.import(@auth, list_id, subscribers, true)
  end


  private

  def initialize_client(identity, retries = 2)
    @auth = {
      :access_token => identity.credentials['token'],
      :refresh_token => identity.credentials['refresh_token']
    }

    cs = CreateSend::CreateSend.new(@auth)
    @client = CreateSend::Client.new(@auth, cs.clients.first.ClientID)
  rescue CreateSend::ExpiredOAuthToken => e
    raise(e) if retries <= 0

    identity.credentials['token'], identity.credentials['expires_at'], identity.credentials['refresh_token'] = cs.refresh_token
    identity.save

    initialize_client(identity, retries - 1)
  end
end
