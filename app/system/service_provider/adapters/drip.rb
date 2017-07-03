module ServiceProvider::Adapters
  class Drip < Base
    configure do |config|
      config.supports_double_optin = true
      config.oauth = true
    end

    def initialize(identity)
      super identity, ::Drip::Client.new(
        access_token: identity.credentials['token'],
        account_id: identity.extra['account_id']
      )
    end

    def lists
      response = client.campaigns(status: 'active')
      response.campaigns.map { |list| list.raw_attributes.slice('id', 'name') }
    end

    def tags
      client.tags.body['tags'].map { |tag| { 'id' => tag, 'name' => tag } }
    end

    def subscribe(list_id, params)
      body = { new_email: params[:email], tags: params[:tags], double_optin: params[:double_optin] }

      if params[:name].present?
        first_name, last_name = params[:name].split(' ', 2)
        body[:custom_fields] = { 'name' => params[:name], 'fname' => first_name, 'lname' => last_name }
      end

      if list_id
        client.subscribe(params[:email], list_id, body)
      else
        # Add subscriber to global account list
        client.create_or_update_subscriber(params[:email], body)
      end
    end
  end
end
