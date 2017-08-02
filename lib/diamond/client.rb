module Diamond
  class Client
    def initialize(endpoint:)
      @endpoint = endpoint
    end

    def track(event: nil, identities:, timestamp:, properties: {})
      raise TypeError, 'Must provide identities as a Hash' unless identities.is_a?(Hash)
      raise ArgumentError, 'Must provide at least one identity' if identities.blank?

      post('/t', {
        event: event,
        identities: identities,
        timestamp: timestamp.to_f,
        properties: properties
      }.compact)
    end

    private

    def post(path, data)
      headers = {
        'Accept': '*/*',
        'Content-Type': 'application/json'
      }

      client = Faraday.new(url: @endpoint, headers: headers) do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      client.post("#{ endpoint_url.path }#{ path }", data.to_json)
    end

    def endpoint_url
      @endpoint_url ||= URI.parse(@endpoint)
    end
  end
end
