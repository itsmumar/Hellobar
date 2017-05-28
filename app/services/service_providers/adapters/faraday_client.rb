module ServiceProviders
  module Adapters
    class FaradayClient < Api
      class RequestError < StandardError; end

      def initialize(url, request: :url_encoded, params: {}, headers: {}, &block)
        client = Faraday.new(url: url, params: params, headers: headers) do |faraday|
          faraday.request request
          faraday.adapter Faraday.default_adapter
          yield faraday if block_given?
        end
        super client
      end
    end
  end
end
