module ServiceProviders
  module Adapters
    class Maropost < Base
      class RequestError < StandardError; end

      def initialize(config_source)
        @account_id = config_source.credentials['username']

        client = Faraday.new(url: config.maropost.url) do |faraday|
          faraday.request :json
          faraday.response :logger unless Rails.env.test?
          faraday.adapter Faraday.default_adapter
          faraday.params = { auth_token: config_source.api_key }
        end

        super client
      end

      def lists
        response = process_response client.get "/accounts/#{ @account_id }/lists.json", no_counts: true
        response.map { |list| list.slice('id', 'name') }
      end

      def subscribe(list_id, params)
        contact = {
          email: params[:email],
          subscribe: true,
          remove_from_dnm: true
        }

        if params[:name].present?
          first_name, last_name = name.split(' ', 2)
          contact.update(first_name: first_name, last_name: last_name)
        end

        response = client.post do |request|
          request.url "/accounts/#{ @account_id }/lists/#{ list_id }/contacts.json"
          request.body = {
            auth_token: @api_key,
            contact: contact
          }
        end

        process_response response
      end

      def batch_subscribe(list_id, subscribers)
        subscribers.each do |subscriber|
          subscribe(list_id, subscriber)
        end
      end

      private

      def process_response(response)
        response_hash = JSON.parse response.body
        return response_hash if response.success?

        raise RequestError, response_hash
      end
    end
  end
end
