describe ServiceProviders::Adapters::Aweber do
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
    ServiceProviders::Adapters::Aweber.configure do |config|
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
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe subscribers
    end
  end
end
