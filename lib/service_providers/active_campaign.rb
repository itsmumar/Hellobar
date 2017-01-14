class ServiceProviders::ActiveCampaign < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'active_campaign').first
      raise "Site does not have a stored ActiveCampaign identity" unless identity
    end

    @identity = identity

    @client = ::ActiveCampaign::Client.new(
                api_endpoint: 'https://' + @identity.extra['app_url'],
                api_key: @identity.api_key)
  end

  def lists
    @client.list_list ids: 'all'
  end

  def subscribe(list_id, email, name = nil, double_optin = false)
    data = { :Email => email }

    if name
      fname, lname = name.split
      data[:FirstName] = fname
      data[:LastName] = lname
    end

    Infusionsoft.contact_add_with_dup_check(data, :Email)
  end

  def batch_subscribe(list_id, subscribers, double_optin = false)
    subscribers.each do |subscriber|
      subscribe(list_id, subscriber[:email], subscriber[:name])
    end
  end
end

# class Router
#   include Rails.application.routes.url_helpers
# end
