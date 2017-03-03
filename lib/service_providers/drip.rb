class ServiceProviders::Drip < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'drip').first
      raise 'Site does not have a stored Drip identity' unless identity
    end

    @identity = identity
    @contact_list = opts[:contact_list]
    @client = Drip::Client.new do |c|
      c.access_token = identity.credentials['token']
      c.account_id   = identity.extra['account_id']
    end
  end

  def accounts
    response = @client.accounts
    @accounts ||= response.accounts
  end

  # TODO: confirm the pagination process
  def campaigns
    response = @client.campaigns(status: 'active')
    @campaigns ||= response.campaigns.map(&:raw_attributes)
  end
  alias_method :lists, :campaigns

  def tags
    response = @client.tags
    response.body['tags'].map { |tag| { 'id' => tag, 'name' => tag } }
  end

  def subscribe(campaign_id, email, name = nil, double_optin = true)
    opts = { new_email: email, tags: @contact_list.tags }

    if name.present?
      split = name.split(' ', 2)
      opts[:custom_fields] = {'name' => name, 'fname' => split[0], 'lname' => split[1]}
    end

    retry_on_timeout do
      if campaign_id
        opts.merge!(double_optin: double_optin)
        @client.subscribe(email, campaign_id, opts)
      else
        # Add subscriber to global account list
        @client.create_or_update_subscriber(email, opts)
      end
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(campaign_id, subscribers, double_optin = true)
    subscribers.each do |subscriber|
      subscribe(campaign_id, subscriber[:email], subscriber[:name], double_optin)
    end
  end
end
