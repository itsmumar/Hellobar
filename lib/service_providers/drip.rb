class ServiceProviders::Drip < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'drip').first
      raise "Site does not have a stored Drip identity" unless identity
    end

    @identity = identity
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
    response = @client.campaigns
    camps = response.campaigns

    @campaigns ||= if camps.count > 0
      camps.map(&:raw_attributes)
    else
      extra = @identity.extra
      [{ 'id' => extra['account_id'], 'name' => extra['account_name'] }]
    end
  end
  alias_method :lists, :campaigns

  def subscribe(list_id, email, name = nil, double_optin = true)
    @client.account_id = list_id

    opts = { new_email: email }

    if name.present?
      split = name.split(' ', 2)
      opts[:custom_fields] = {"name" => name, "fname" => split[0], "lname" => split[1]}
    end

    retry_on_timeout do
      @client.create_or_update_subscriber(email, opts)
    end
  end

  # send subscribers in [{:email => '', :name => ''}, {:email => '', :name => ''}] format
  def batch_subscribe(list_id, subscribers, double_optin = true)
    @client.account_id = list_id

    batch = subscribers.map do |subscriber|
      {email: subscriber[:email], new_email: subscriber[:email]}.tap do |entry|
        if subscriber[:name].present?
          split = subscriber[:name].split(' ', 2)
          entry[:custom_fields] = {:name => subscriber[:name], :fname => split[0], :lname => split[1]}
        end
      end
    end

    @client.create_or_update_subscribers(batch)
  end
end
