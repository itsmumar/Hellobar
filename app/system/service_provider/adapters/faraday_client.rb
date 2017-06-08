module ServiceProvider::Adapters
  class FaradayClient < Base
    class RequestError < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
        super "[#{ response.status } #{ response.reason_phrase }] #{ response.body }"
      end
    end

    def initialize(url = nil, request: :url_encoded, params: {}, headers: {})
      client = Faraday.new(url: url, params: params, headers: headers) do |faraday|
        faraday.request request
        faraday.adapter Faraday.default_adapter
        yield faraday if block_given?
      end
      super client
    end

    private

    def process_response(response)
      response_hash = JSON.parse response.body
      return response_hash if response.success?

      raise RequestError, response
    end
  end
end
