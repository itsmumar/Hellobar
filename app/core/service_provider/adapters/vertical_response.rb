module ServiceProvider::Adapters
  class VerticalResponse < Base
    configure do |config|
      config.client_id = Settings.identity_providers['verticalresponse']['client_id']
      config.secret = Settings.identity_providers['verticalresponse']['secret']
      config.supports_double_optin = false
      config.oauth = true
    end

    rescue_from ::VerticalResponse::API::Error do |e|
      raise e unless e.message == 'Contact already exists.'
    end

    def initialize(identity)
      super identity, ::VerticalResponse::API::OAuth.new(identity.credentials['token'])
    end

    def lists
      client.lists.select { |list| list.response.success? }.map do |list|
        { 'id' => list.id, 'name' => list.response.attributes['name'] }
      end
    end

    def subscribe(list_id, params)
      options = { email: params[:email] }

      if params[:name].present?
        first_name, last_name = params[:name].split(' ', 2)
        options[:first_name] = first_name if first_name.present?
        options[:last_name] = last_name if last_name.present?
      end

      client.find_list(list_id).create_contact(options)
    end
  end
end
