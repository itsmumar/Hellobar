module ServiceProviders
  module Adapters
    class Maropost < FaradayClient
      register :maropost

      def initialize(config_source)
        account_id = config_source.credentials['username']
        url = "#{ config.url }/accounts/#{ account_id }"

        super url, request: :json, params: { auth_token: config_source.api_key }
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
          first_name, last_name = params[:name].split(' ', 2)
          contact.update(first_name: first_name, last_name: last_name)
        end

        response = client.post do |request|
          request.url "lists/#{ list_id }/contacts.json"
          request.body = { contact: contact }
        end

        process_response response
      end
    end
  end
end
