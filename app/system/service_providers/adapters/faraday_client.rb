module ServiceProviders
  module Adapters
    class FaradayClient < Base
      class RequestError < StandardError; end

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

        raise RequestError, response_hash.to_json
      end
    end
  end
end
