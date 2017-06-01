describe ServiceProviders::Adapters::Maropost do
  define_urls(
    lists: 'http://maropost.url/accounts/12345/lists.json?auth_token=api_key&no_counts=true',
    subscribe: 'http://maropost.url/accounts/12345/lists/4567456/contacts.json?auth_token=api_key'
  )

  let(:identity) { double('identity', provider: 'maropost', api_key: 'api_key', credentials: { 'username' => '12345' }) }

  include_examples 'service provider'

  before do
    ServiceProviders::Provider.configure do |config|
      config.maropost.url = 'http://maropost.url'
    end
  end

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      params = { auth_token: 'api_key' }
      expect(Faraday).to receive(:new).with(url: 'http://maropost.url/accounts/12345', params: params, headers: {}).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    body = { contact: { email: 'example@email.com', subscribe: true, remove_from_dnm: true, first_name: 'FirstName', last_name: 'LastName' } }.to_json
    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe 'list_id', subscribers
    end
  end
end
