module ServiceProvider::Adapters
  class FaradayClient < Base
    class RaiseError < Faraday::Response::RaiseError
      %w[Unauthorized Conflict BadRequest].each do |name|
        Faraday.const_set name, Class.new(Faraday::ClientError)
      end

      def on_complete(env)
        case env[:status]
        when 400
          raise ServiceProvider::InvalidSubscriberError, response_values(env)
        when 401
          raise Faraday::Unauthorized, response_values(env)
        when 409
          raise Faraday::Conflict, response_values(env)
        when 400..600
          raise Faraday::ClientError, response_values(env)
        end
      end
    end

    def initialize(url = nil, request: :url_encoded, params: {}, headers: {})
      client = Faraday.new(url: url, params: params, headers: headers) do |faraday|
        faraday.request request
        faraday.use RaiseError
        faraday.adapter Faraday.default_adapter
        yield faraday if block_given?
      end
      super client
    end

    private

    def process_response(response)
      JSON.parse response.body
    end
  end
end
