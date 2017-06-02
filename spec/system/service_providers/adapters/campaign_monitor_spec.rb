describe ServiceProviders::Adapters::CampaignMonitor do
  define_urls(
    clients: 'https://api.createsend.com/api/v3.1/clients.json',
    lists: 'https://api.createsend.com/api/v3.1/clients/4a397ccaaa55eb4e6aa1221e1e2d7122/lists.json',
    subscribers: 'https://api.createsend.com/api/v3.1/subscribers/4567456.json',
    import: 'https://api.createsend.com/api/v3.1/subscribers/4567456/import.json'
  )

  let(:identity) do
    double('identity', provider: 'campaign_monitor', credentials: { 'token' => 'token', 'refresh_token' => 'refresh_token' })
  end

  include_examples 'service provider'

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
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
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
    let!(:create_request) { allow_request :post, :subscribers, body: body }

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(create_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:body) do
      {
        'Subscribers': [
          { 'EmailAddress': 'example1@email.com', 'Name': 'FirstName LastName' },
          { 'EmailAddress': 'example2@email.com', 'Name': 'FirstName LastName' }
        ],
        'Resubscribe': true,
        'QueueSubscriptionBasedAutoresponders': true,
        'RestartSubscriptionBasedAutoresponders': false
      }
    end
    let!(:import_request) { allow_request :post, :import, body: body }

    let(:subscribers) { [{ email: 'example1@email.com', name: name }, { email: 'example2@email.com', name: name }] }

    it 'calls #subscribe for each subscriber' do
      provider.batch_subscribe list_id, subscribers
      expect(import_request).to have_been_made
    end
  end
end
