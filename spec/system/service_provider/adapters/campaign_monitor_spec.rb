describe ServiceProvider::Adapters::CampaignMonitor do
  let(:defined_urls) do
    {
      clients: 'https://api.createsend.com/api/v3.1/clients.json',
      clients_unauthorized: 'https://api.createsend.com/api/v3.1/clients.json',
      clients_expired_token: 'https://api.createsend.com/api/v3.1/clients.json',
      lists: 'https://api.createsend.com/api/v3.1/clients/4a397ccaaa55eb4e6aa1221e1e2d7122/lists.json',
      subscribe: 'https://api.createsend.com/api/v3.1/subscribers/4567456.json',
      subscribe_unauthorized: 'https://api.createsend.com/api/v3.1/subscribers/4567456.json',
      subscribe_expired_token: 'https://api.createsend.com/api/v3.1/subscribers/4567456.json',
      refresh_token: 'https://api.createsend.com/oauth/token',
      refresh_token_unauthorized: 'https://api.createsend.com/oauth/token'
    }
  end

  let(:credentials) { Hash['token' => 'token', 'refresh_token' => 'refresh_token'] }

  let(:new_token_credentials) do
    {
      token: 'new_token',
      expires_in: Time.current.to_i + 1209600,
      refresh_token: 'new_refresh_token',
      expires: true
    }
  end

  let(:identity) { double 'identity', provider: 'createsend', credentials: credentials }

  include_context 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token', refresh_token: 'refresh_token' } }

    it 'initializes ::CreateSend::CreateSend' do
      expect(::CreateSend::CreateSend).to receive(:new).with(auth).and_call_original
      expect(adapter.client).to be_a ::CreateSend::CreateSend
    end
  end

  describe '#lists' do
    it 'returns array of id => name' do
      allow_requests :get, :clients, :lists

      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end

    context 'when CreateSend::Unauthorized is raised' do
      it 'calls DestroyIdentity' do
        allow_request :get, :clients_unauthorized

        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)

        provider.lists
      end
    end

    context 'when CreateSend::ExpiredOAuthToken is raised', :freeze do
      it 'sends request for new OAuth token and retries the request' do
        # first request will raise ExpiredOauthToken, second wil succeed
        allow_request(:get, :clients_expired_token)
          .then
          .to_return response_for(:get, :clients)

        allow_request :get, :lists
        allow_request :post, :refresh_token

        expect(identity).to receive(:update)
          .with(credentials: new_token_credentials)
        expect(DestroyIdentity).not_to receive_service_call

        expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
      end
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        EmailAddress: 'example@email.com',
        Name: 'FirstName LastName',
        CustomFields: [],
        Resubscribe: true,
        RestartSubscriptionBasedAutoresponders: true
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    let(:subscribe) { provider.subscribe(email: email, name: name) }

    it 'sends subscribe request' do
      subscribe
      expect(subscribe_request).to have_been_made
    end

    context 'when CreateSend::Unauthorized is raised' do
      it 'calls DestroyIdentity' do
        allow_request :post, :subscribe_unauthorized, body: body

        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)

        subscribe
      end
    end

    context 'when CreateSend::ExpiredOAuthToken is raised', :freeze do
      it 'sends request for new OAuth token and retries the request' do
        # first request will raise ExpiredOauthToken, second wil succeed
        allow_request(:post, :subscribe_expired_token)
          .then
          .to_return response_for(:post, :subscribe)

        allow_request :post, :refresh_token

        expect(identity).to receive(:update)
          .with(credentials: new_token_credentials)
        expect(DestroyIdentity).not_to receive_service_call

        subscribe
      end

      it 'bails out after request for new Oauth token fails' do
        # first request will raise ExpiredOauthToken
        allow_request :post, :subscribe_expired_token

        # request for refresh token will raise RuntimeError, then CreateSend::Unauthorized
        allow_request :post, :refresh_token_unauthorized

        expect(identity).not_to receive(:update)
        expect(DestroyIdentity).to receive_service_call

        subscribe
      end

      it 'bails out after if refreshed Oauth token is no good' do
        # two requests will raise ExpiredOauthToken
        allow_request :post, :subscribe_expired_token

        allow_request :post, :refresh_token

        allow(identity).to receive(:update)
        expect(DestroyIdentity).to receive_service_call

        subscribe
      end
    end
  end
end
