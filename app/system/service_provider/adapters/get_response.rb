module ServiceProvider::Adapters
  class GetResponse < FaradayClient
    configure do |config|
      config.requires_api_key = true
      config.supports_cycle_day = true
    end

    def initialize(identity)
      super identity, 'https://api.getresponse.com/v3', headers: { 'X-Auth-Token' => "api-key #{ identity.api_key }" }
    end

    def lists
      response = process_response client.get 'campaigns', perPage: 500
      response.map { |list| { 'id' => list['campaignId'], 'name' => list['name'] } }
    end

    def tags
      response = process_response client.get 'tags', perPage: 500
      response.map { |tag| { 'id' => tag['tagId'].to_s, 'name' => tag['name'] } }
    end

    def subscribe(list_id, params, cycle_day: nil)
      request_body = {
        email: params[:email],
        campaign: {
          campaignId: list_id
        },
        tags: params[:tags].map { |tag| Hash[tagId: tag] }
      }
      request_body[:name] = params[:name] if params[:name].present?

      request_body.update(dayOfCycle: cycle_day) if cycle_day.present?

      process_response client.post 'contacts', request_body
    end

    private

    def test_connection
      client.get 'campaigns', perPage: 500
    end
  end
end
