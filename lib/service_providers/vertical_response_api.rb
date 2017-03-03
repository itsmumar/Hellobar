class ServiceProviders::VerticalResponseApi < ServiceProviders::Email
  def initialize(opts = {})
    if opts[:identity]
      identity = opts[:identity]
    elsif opts[:site]
      identity = opts[:site].identities.where(:provider => 'verticalresponse').first
      raise "Site does not have a stored Vertical Response identity" unless identity
    end

    @client = VerticalResponse::API::OAuth.new identity.credentials['token']
  end

  def lists
    @client.lists.map do |list|
      if list.response.success?
        { 'id' => list.id, 'name' => list.response.attributes['name'] }
      end
    end
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    first_name, last_name = split_name(name)
    handle_errors do
      @client.find_list(list_id).create_contact(
        {
          email: email,
          first_name: first_name,
          last_name: last_name
        }
      )
    end
  end

  def batch_subscribe(list_id, subscribers, double_optin = true)
    handle_errors do
      @client.find_list(list_id).create_contacts(
        subscribers.map do |subscriber|
          first_name, last_name = split_name(subscriber[:name])
          {
            email: subscriber[:email],
            first_name: first_name,
            last_name: last_name
          }
        end
      )
    end
  end

  private

  def handle_errors
    yield
  rescue VerticalResponse::API::Error => e
    if e.message == "Contact already exists."
      # Do nothing, this is raised when the email already exists or email is invalid
    else
      log "Vertical Response error '#{e.message}'"
    end
  end

  def split_name(name)
    if name
      name.split(' ', 2)
    else
      ["", ""]
    end
  end
end
