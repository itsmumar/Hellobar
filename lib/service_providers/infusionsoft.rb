class ServiceProviders::Infusionsoft < ServiceProviders::Email
  include ActionView::Helpers::SanitizeHelper

  def initialize(opts = {})
    super opts

    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(provider: 'infusionsoft').first
      raise 'Site does not have a stored Infusionsoft identity' unless identity
    end

    @identity = identity

    Infusionsoft.configure do |config|
      config.api_url = @identity.extra['app_url']
      config.api_key = @identity.api_key
    end
  end

  def tags
    Infusionsoft.data_query('ContactGroup', 1_000, 0, {}, %w(GroupName Id))
                .map { |result| { 'name' => result['GroupName'], 'id' => result['Id'] } }
                .sort_by { |result| result['name'] }
  end

  def subscribe(_, email, name = nil, _double_optin = false)
    data = { Email: email }

    if name
      fname, lname = name.split
      data[:FirstName] = fname
      data[:LastName] = lname
    end

    infusionsoft_user_id = Infusionsoft.contact_add_with_dup_check(data, :Email)

    @contact_list.tags.each do |tag_id|
      Infusionsoft.contact_add_to_group(infusionsoft_user_id, tag_id)
    end
  end

  def batch_subscribe(_, subscribers, _double_optin = false)
    subscribers.each do |subscriber|
      subscribe(nil, subscriber[:email], subscriber[:name])
    end
  end

  def valid?
    !!tags
  rescue => error
    log "Getting lists raised #{error}"
    false
  end
end

class Router
  include Rails.application.routes.url_helpers
end
