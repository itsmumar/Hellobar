class ServiceProviders::AWeber < ServiceProviders::Email
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(provider: 'createsend').first
      raise 'Site does not have a stored AWeber identity' unless identity
    end

    oauth = ::AWeber::OAuth.new(Hellobar::Settings[:identity_providers][:aweber][:consumer_key], Hellobar::Settings[:identity_providers][:aweber][:consumer_secret])
    oauth.authorize_with_access(identity.credentials['token'], identity.credentials['secret'])

    @contact_list = opts[:contact_list]
    @client = ::AWeber::Base.new(oauth)
  end

  def lists
    @client.account.lists.map { |_, v| { 'id' => v.id, 'name' => v.name } }
  rescue => _
    []
  end

  def subscribe(list_id, email, name = nil, _double_optin = true)
    handle_errors do
      # AWeber will always force double-optin: https://help.aweber.com/entries/22883171-Why-Was-a-Confirmation-Message-Sent-When-Confirmation-Was-Disabled-
      @client.account.lists[list_id.to_i].subscribers.create('name' => name,
                                                             'email' => email,
                                                             'tags' => @contact_list.tags.to_json)
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, _double_optin = true)
    # AWeber does not provider a batch subscribe operation, so we have do this one-by-one
    subscribers.each do |subscriber|
      handle_errors do
        subscribe(list_id, subscriber[:email], subscriber[:name])
      end
      sleep(2) # Aweber only allows 60 calls per minute so we rate this at 30 just to be safe
    end
  end

  def handle_errors
    yield
  rescue AWeber::CreationError
    # Do nothing, this is raised when the email already exists or email is invalid
  end
end
