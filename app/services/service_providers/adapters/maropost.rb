module ServiceProviders
  module Adapters
    class Maropost < Base
      class RequestError < StandardError; end

      register :maropost

      def initialize(config_source)
        @account_id = config_source.credentials['username']
        url = "#{ config.maropost.url }/accounts/#{ @account_id }"

        client = Faraday.new(url: url, params: { auth_token: config_source.api_key }) do |faraday|
          faraday.request :json
          faraday.adapter Faraday.default_adapter
        end

        super client
      end

      def lists
        response = process_response client.get 'lists.json', no_counts: true
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
          request.url "lists/#{ list_id }/contacts.json"
          request.body = { contact: contact }
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
