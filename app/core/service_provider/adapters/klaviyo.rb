module ServiceProvider::Adapters
  class Klaviyo < FaradayClient
    configure do |config|
      config.requires_api_key = true
    end

    def initialize(identity)
      super identity, 'https://a.klaviyo.com/api/v2', params: { api_key: identity.api_key }
    end

    def lists
      parsed_response = process_response client.get 'lists'
      parsed_response.map do |list|
        {
          'id' => list['list_id'],
          'name' => list['list_name']
        }
      end
    end

    def subscribe(list_id, params)
      profile = {
        email: params[:email]
      }

      if params[:name].present?
        first_name, last_name = params[:name].split(' ', 2)

        profile[:first_name] = first_name
        profile[:last_name] = last_name.to_s
      end

      client.post "list/#{ list_id }/subscribe" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = { profiles: [profile] }.to_json
      end
    end

    private

    def test_connection
      client.get 'lists'
    end
  end
end
