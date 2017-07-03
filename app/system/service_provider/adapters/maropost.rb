module ServiceProvider::Adapters
  class Maropost < FaradayClient
    configure do |config|
      config.requires_account_id = true
      config.requires_api_key = true
      config.url = Settings.identity_providers['maropost']['url']
    end

    rescue_from Faraday::Unauthorized do
      @identity.destroy_and_notify_user
    end

    def initialize(identity)
      account_id = identity.credentials['username']
      url = "#{ config.url }/accounts/#{ account_id }"

      super identity, url, request: :json, params: { auth_token: identity.api_key }
    end

    def lists
      response = process_response client.get 'lists.json', no_counts: true
      response.map { |list| list.slice('id', 'name') }
    end

    def subscribe(list_id, params)
      contact = {
        email: params[:email],
        subscribe: true,
        remove_from_dnm: true
      }

      if params[:name].present?
        first_name, last_name = params[:name].split(' ', 2)
        contact.update(first_name: first_name, last_name: last_name)
      end

      response = client.post do |request|
        request.url "lists/#{ list_id }/contacts.json"
        request.body = { contact: contact }
      end

      process_response response
    end

    private

    def test_connection
      client.get 'lists.json', no_counts: true
    end
  end
end
