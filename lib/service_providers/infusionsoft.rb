class ServiceProviders::Infusionsoft < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'infusionsoft').first
      raise "Site does not have a stored Infusionsoft identity" unless identity
    end

    @identity = identity

    Infusionsoft.configure do |config|
      config.api_url = @identity.extra['app_url']
      config.api_key = @identity.api_key
    end
  end

  def lists
    # Infusionsoft doesn't have the concept of lists, just contacts
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    # Infusionsoft.contact_add(email, name)
  end

  def batch_subscribe(list_id, subscribers, double_optin = true)
  end
end

class Router
  include Rails.application.routes.url_helpers
end
