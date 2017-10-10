require 'createsend'

module ServiceProvider::Adapters
  class CampaignMonitor < Base
    configure do |config|
      config.oauth = true
    end

    rescue_from CreateSend::Unauthorized, with: :notify_user_about_unauthorized_error

    def initialize(identity)
      super identity, CreateSend::CreateSend.new(
        access_token: identity.credentials['token'],
        refresh_token: identity.credentials['refresh_token']
      )
    end

    def lists
      client.clients.flat_map do |raw_client|
        client_api = CreateSend::Client.new(client.auth_details, raw_client['ClientID'])
        client_api.lists.map { |raw_list| { 'id' => raw_list['ListID'], 'name' => raw_list['Name'] } }
      end
    end

    def subscribe(list_id, params)
      email, name = params.values_at(:email, :name)

      with_token_refresh do
        CreateSend::Subscriber.add(client.auth_details, list_id, email, name, [], true, true)
      end
    end

    private

    def with_token_refresh
      tries ||= 2

      yield
    rescue CreateSend::ExpiredOAuthToken
      refresh_token

      if (tries -= 1) > 0
        retry
      else
        raise_unauthorized_exception
      end
    end

    def refresh_token
      access_token, expires_in, refresh_token = client.refresh_token

      update_identity(
        token: access_token,
        expires_in: Time.current.to_i + expires_in,
        refresh_token: refresh_token,
        expires: true
      )
    rescue RuntimeError => exception
      # log unsuccessful refresh_token attempts
      Raven.capture_exception exception

      # raise unauthorized error to disconnect identity
      raise_unauthorized_exception
    end

    def update_identity credentials
      identity.update credentials: credentials
    end

    def raise_unauthorized_exception
      data = OpenStruct.new Code: 666, Message: 'Could not refresh access token'
      raise CreateSend::Unauthorized, data
    end
  end
end
