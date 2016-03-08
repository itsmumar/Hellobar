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
    []
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
end

class Router
  include Rails.application.routes.url_helpers
end
