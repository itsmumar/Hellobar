describe ServiceProviders::Adapters::Maropost, :no_vcr do
  define_urls(
    lists: 'http://maropost.url/accounts/12345/lists.json?auth_token=api_key&no_counts=true',
    subscribe: 'http://maropost.url/accounts/12345/lists/4567456/contacts.json?auth_token=api_key'
  )

  let(:config_source) { double('config_source', api_key: 'api_key', credentials: { 'username' => '12345' }) }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  before do
    ServiceProviders::Provider.configure do |config|
      config.maropost.url = 'http://maropost.url'
    end
  end

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      params = { auth_token: 'api_key' }
      expect(Faraday).to receive(:new).with(url: 'http://maropost.url/accounts/12345', params: params).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    body = { contact: { email: 'example@email.com', subscribe: true, remove_from_dnm: true } }.to_json
    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      adapter.subscribe(list_id, email: 'example@email.com')
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber)
      end
      adapter.batch_subscribe 'list_id', subscribers
    end
  end
end
