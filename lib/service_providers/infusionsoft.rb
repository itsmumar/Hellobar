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
    # TODO: Fill in infusion soft api client here
    @client = nil
  end

  def lists
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
  end

  def batch_subscribe(list_id, subscribers, double_optin = true)
  end

  def log(message)
  end

  def handle_error(error)
  end
end

class Router
  include Rails.application.routes.url_helpers
end
