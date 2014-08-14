class ServiceProviders::AWeber < ServiceProvider
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

  def subscribe(list_id, email, name = nil)
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
    end
  end
end
