class ServiceProviders::ActiveCampaign < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(provider: 'active_campaign').first
      raise 'Site does not have a stored ActiveCampaign identity' unless identity
    end

    @identity = identity

    @client = ::ActiveCampaign::Client.new(
      api_endpoint: 'https://' + @identity.extra['app_url'] + '/admin/api.php',
      api_key: @identity.api_key
    )
  end

  def lists
    response = @client.list_list ids: 'all'

    if response['result_code'] == 1
      response['results']
    else
      raise response['result_message']
    end
  end

  def subscribe(list_id, email, name = nil, _double_optin = false)
    contact = {}
    contact[:email] = email
    contact["p[#{list_id}]"] = list_id if list_id

    if name
      fname, lname = name.split
      contact[:first_name] = fname
      contact[:last_name] = lname
    end

    @client.contact_sync(contact)
  end

  def batch_subscribe(list_id, subscribers, _double_optin = false)
    subscribers.each do |subscriber|
      subscribe(list_id, subscriber[:email], subscriber[:name])
    end
  end

  def valid?
    !!lists
  rescue => error
    log "Getting lists raised #{error}"
    false
  end
end
