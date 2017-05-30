describe ServiceProviders::Adapters::AWeber, :no_vcr do
  define_urls(
    accounts: 'https://api.aweber.com/1.0/accounts?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
    lists: 'https://api.aweber.com/1.0/accounts/1118926/lists?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
    subscribers: 'https://api.aweber.com/1.0/accounts/1118926/lists/4567456/subscribers?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0',
    subscriber: 'https://api.aweber.com/1.0/accounts/1118926/lists/4567456/subscribers/63461580?oauth_consumer_key=consumer_key{&oauth_nonce,oauth_signature,oauth_signature_method,oauth_timestamp}&oauth_token=token&oauth_version=1.0'
  )

  let(:identity) { double('identity', provider: 'aweber', credentials: { 'token' => 'token', 'secret' => 'secret' }) }

  include_examples 'service provider'

  before do
    ServiceProviders::Provider.configure do |config|
      config.aweber.consumer_key = 'consumer_key'
      config.aweber.consumer_secret = 'consumer_secret'
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
    allow_requests :get, :accounts, :lists

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_requests :get, :accounts, :lists, :subscribers, :subscriber

    body = { 'name' => 'FirstName LastName', 'tags' => '["id1","id2"]', 'email' => 'example@email.com', 'ws.op' => 'create' }
    allow_request :post, :subscribers, body: body do |stub|
      let(:create_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(create_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber)
      end
      adapter.batch_subscribe list_id, subscribers
    end
  end
end
