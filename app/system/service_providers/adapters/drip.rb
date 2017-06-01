module ServiceProviders
  module Adapters
    class Drip < Api
      register :drip

      def initialize(config_source)
        super ::Drip::Client.new(
          access_token: config_source.credentials['token'],
          account_id: config_source.extra['account_id']
        )
      end

      def lists
        response = client.campaigns(status: 'active')
        response.campaigns.map { |list| list.raw_attributes.slice('id', 'name') }
      end

      def tags
        client.tags.body['tags'].map { |tag| { 'id' => tag, 'name' => tag } }
      end

      def subscribe(list_id, params, tags: [])
        body = { new_email: params[:email], tags: tags }

        if params[:name].present?
          first_name, last_name = name.split(' ', 2)
          body[:custom_fields] = { 'name' => params[:name], 'fname' => first_name, 'lname' => last_name }
        end

        if list_id
          body[:double_optin] = params[:double_optin]
          client.subscribe(params[:email], list_id, body)
        else
          # Add subscriber to global account list
          client.create_or_update_subscriber(email, body)
        end
      end
    end
  end
end
