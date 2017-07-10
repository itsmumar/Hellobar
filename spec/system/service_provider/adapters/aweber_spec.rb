describe ServiceProvider::Adapters::Aweber do
  let(:defined_urls) do
    {
      accounts: 'https://api.aweber.com/1.0/accounts?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
      lists: 'https://api.aweber.com/1.0/accounts/1118926/lists?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
      subscribers: 'https://api.aweber.com/1.0/accounts/1118926/lists/4567456/subscribers?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
      subscriber: 'https://api.aweber.com/1.0/accounts/1118926/lists/4567456/subscribers/63461580?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0'
    }
  end

  let(:identity) { double('identity', provider: 'aweber', credentials: { 'token' => 'token', 'secret' => 'secret' }) }

  include_examples 'service provider'

  before do
    ServiceProvider::Adapters::Aweber.configure do |config|
      config.consumer_key = 'consumer_key'
      config.consumer_secret = 'consumer_secret'
    end
  end

  describe '#initialize' do
    let(:oauth) { double('oauth') }

    it 'initializes ::AWeber::Base' do
      expect(::AWeber::OAuth).to receive(:new).with('consumer_key', 'consumer_secret').and_return(oauth)
      expect(oauth).to receive(:authorize_with_access).with('token', 'secret')
      expect(::AWeber::Base).to receive(:new).with(oauth).and_call_original

      expect(adapter.client).to be_a ::AWeber::Base
    end
  end

  describe '#lists' do
    before { allow_requests :get, :accounts, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    before { allow_requests :get, :accounts, :lists, :subscribers, :subscriber }

    let(:body) { { 'name' => 'FirstName LastName', 'tags' => '["id1","id2"]', 'email' => 'example@email.com', 'ws.op' => 'create' } }
    let!(:create_request) { allow_request :post, :subscribers, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(create_request).to have_been_made
    end

    context 'when AWeber::CreationError is raised' do
      before { allow_any_instance_of(::AWeber::Base).to receive(:account).and_raise(AWeber::CreationError) }

      it 'ignores errors' do
        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end

      context 'when error message is "Invalid consumer key or access token key"' do
        let(:message) { 'Invalid consumer key or access token key' }
        before { allow_any_instance_of(::AWeber::Base).to receive(:account).and_raise(AWeber::CreationError, message) }

        it 'destroys identity and notify user' do
          expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
          expect { provider.subscribe(email: email, name: name) }.not_to raise_error
        end
      end
    end
  end
end
