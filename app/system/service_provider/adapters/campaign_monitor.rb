require 'createsend'

module ServiceProvider::Adapters
  class CampaignMonitor < Base
    configure do |config|
      config.oauth = true
    end

    rescue_from CreateSend::Unauthorized, with: :destroy_identity

    def initialize(identity)
      @identity = identity
      super CreateSend::CreateSend.new(
        access_token: identity.credentials['token'],
        refresh_token: identity.credentials['refresh_token']
      )
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

    def batch_subscribe(list_id, subscribers, double_optin: nil) # rubocop:disable Lint/UnusedMethodArgument
      subscribers = subscribers.map { |s| { 'EmailAddress' => s[:email], 'Name' => s[:name] } }
      CreateSend::Subscriber.import(client.auth_details, list_id, subscribers, true, true)
    end

    private

    def destroy_identity
      @identity.destroy_and_notify_user
    end
  end
end
