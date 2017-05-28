describe ServiceProviders::Adapters::CampaignMonitor, :no_vcr do
  define_urls(
    clients: 'https://api.createsend.com/api/v3.1/clients.json',
    lists: 'https://api.createsend.com/api/v3.1/clients/4a397ccaaa55eb4e6aa1221e1e2d7122/lists.json',
    subscribers: 'https://api.createsend.com/api/v3.1/subscribers/4567456.json',
    import: 'https://api.createsend.com/api/v3.1/subscribers/4567456/import.json'
  )

  let(:config_source) { double('config_source', credentials: { 'token' => 'token', 'refresh_token' => 'refresh_token' }) }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  before do
    ServiceProviders::Provider.configure do |config|
      config.aweber.consumer_key = 'consumer_key'
      config.aweber.consumer_secret = 'consumer_secret'
    end
  end

  describe '#initialize' do
    let(:auth) { { access_token: 'token', refresh_token: 'refresh_token' } }

    it 'initializes ::CreateSend::CreateSend' do
      expect(::CreateSend::CreateSend).to receive(:new).with(auth).and_call_original
      expect(adapter.client).to be_a ::CreateSend::CreateSend
    end
  end

  describe '#lists' do
    allow_requests :get, :clients, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribers, body: { 'EmailAddress': 'example@email.com', 'Name': nil, 'CustomFields': [], 'Resubscribe': true, 'RestartSubscriptionBasedAutoresponders': true } do |stub|
      let(:create_request) { stub }
    end

    it 'sends subscribe request' do
      adapter.subscribe(list_id, email: 'example@email.com')
      expect(create_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    allow_request :post, :import, body: { 'Subscribers': [{ 'EmailAddress': 'example1@email.com', 'Name': nil }, { 'EmailAddress': 'example2@email.com', 'Name': nil }], 'Resubscribe': true, 'QueueSubscriptionBasedAutoresponders': true, 'RestartSubscriptionBasedAutoresponders': false } do |stub|
      let(:import_request) { stub }
    end
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      adapter.batch_subscribe list_id, subscribers
      expect(import_request).to have_been_made
    end
  end
end
