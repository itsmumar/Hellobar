module ServiceProvider::Adapters
  class Iterable < FaradayClient
    configure do |config|
      config.requires_api_key = true
    end

    def initialize(identity)
      super identity, 'https://api.iterable.com/api', params: { api_key: identity.api_key }
    end

    def lists
      parsed_response = process_response client.get 'lists'
      parsed_response['lists'].map do |list|
        Hash['id' => list['id'], 'name' => list['name']]
      end
    end

    def subscribe(list_id, params)
      request_body = {
        listId: list_id.to_i,
        subscribers: [{
          email: params[:email]
        }]
      }

      if params[:name].present?
        first_name, last_name = params[:name].split(' ', 2)

        request_body[:subscribers].first[:dataFields] = {
          firstName: first_name,
          lastName: last_name.to_s
        }
      end

      client.post 'lists/subscribe', request_body.to_json
    end

    private

    def test_connection
      client.get 'lists'
    end
  end
end
