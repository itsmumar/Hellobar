class ServiceProviders::AWeber < ServiceProviders::Email
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'createsend').first
      raise "Site does not have a stored AWeber identity" unless identity
    end

    oauth = ::AWeber::OAuth.new(Hellobar::Settings[:identity_providers][:aweber][:consumer_key], Hellobar::Settings[:identity_providers][:aweber][:consumer_secret])
    oauth.authorize_with_access(identity.credentials['token'], identity.credentials['secret'])

    @client = ::AWeber::Base.new(oauth)
  end

  def lists
    @client.account.lists.map {|k,v| {'id' => v.id, 'name' => v.name}} rescue []
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    # AWeber will always force double-optin: https://help.aweber.com/entries/22883171-Why-Was-a-Confirmation-Message-Sent-When-Confirmation-Was-Disabled-
    @client.account.lists[list_id.to_i].subscribers.create({'name' => name, 'email' => email})
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    # AWeber does not provider a batch subscribe operation, so we have do this one-by-one
    subscribers.each do |subscriber|
      begin
        subscribe(list_id, subscriber[:email], subscriber[:name])
      rescue ::AWeber::CreationError => e
        # this is raised if a subscriber already belongs to the list
        log e.inspect
      end
      sleep(2) # Aweber only allows 60 calls per minute so we rate this at 30 just to be safe 
    end
  end
end
