require 'createsend'

module ServiceProviders
  module Adapters
    class CampaignMonitor < Base
      def initialize(config_source)
        auth = {
          access_token: config_source.credentials['token'],
          refresh_token: config_source.credentials['refresh_token']
        }
        super CreateSend::CreateSend.new(auth)
      end

      def lists
        client.clients.flat_map do |raw_client|
          client_api = CreateSend::Client.new(client.auth_details, raw_client['ClientID'])
          client_api.lists.map { |raw_list| { 'id' => raw_list['ListID'], 'name' => raw_list['Title'] } }
        end
      end

      def subscribe(list_id, params)
        email, name = params.values_at(:email, :name)
        CreateSend::Subscriber.add(client.auth_details, list_id, email, name, [], true, true)
      end

      def batch_subscribe(list_id, subscribers)
        subscribers = subscribers.map { |s| { 'EmailAddress' => s[:email], 'Name' => s[:name] } }
        CreateSend::Subscriber.import(client.auth_details, list_id, subscribers, true, true)
      end
    end
  end
end
