module ServiceProviders
  module Adapters
    class Drip < Base
      register :drip

      def initialize(config_source)
        client = ::Drip::Client.new(
          access_token: config_source.credentials['token'],
          account_id: config_source.extra['account_id']
        )
        super client
      end

      def lists
        response = client.campaigns(status: 'active')
        response.campaigns.map { |list| list.raw_attributes.slice('id', 'name') }
      end

      def tags
        client.tags.body['tags'].map { |tag| { 'id' => tag, 'name' => tag } }
      end

      def subscribe(list_id, params, double_optin = true, tags: [])
        body = { new_email: params[:email], tags: tags }

        if params[:name].present?
          first_name, last_name = name.split(' ', 2)
          body[:custom_fields] = { 'name' => params[:name], 'fname' => first_name, 'lname' => last_name }
        end

        retry_on_timeout do
          if list_id
            body[:double_optin] = double_optin
            client.subscribe(params[:email], list_id, body)
          else
            # Add subscriber to global account list
            client.create_or_update_subscriber(email, body)
          end
        end
      end

      def batch_subscribe(list_id, subscribers, double_optin = true)
        subscribers.each do |subscriber|
          subscribe(list_id, subscriber, double_optin)
        end
      end

      private

      def retry_on_timeout(max: 1)
        original_max = max
        loop do
          raise "Timed out too many times (#{ original_max })" if max == 0
          max -= 1

          begin
            yield(self)
            break # will not break if exception is raised
          rescue Net::OpenTimeout => e
            Rails.logger.error "Caught #{ e }, retrying after 5 seconds"
            sleep 5
          end
        end
      end
    end
  end
end
