module ServiceProvider::Adapters
  class Maropost < FaradayClient
    configure do |config|
      config.requires_account_id = true
      config.requires_api_key = true
      config.url = Settings.identity_providers['maropost']['url']
    end

    def initialize(identity)
      account_id = identity.credentials['username']
      url = "#{ config.url }/accounts/#{ account_id }"

      super url, request: :json, params: { auth_token: identity.api_key }
    end

    def lists
      response = process_response client.get 'lists.json', no_counts: true
      response.map { |list| list.slice('id', 'name') }
    end

    def tags
      response = process_response client.get 'tags.json', no_counts: true
      response.map { |list| { 'id' => list['name'], 'name' => list['name'] } }
    end

    def subscribe(list_id, params)
      contact = {
        email: params[:email],
        subscribe: true,
        remove_from_dnm: true,
        add_tags: params.fetch(:tags, [])
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
