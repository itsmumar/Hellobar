describe ServiceProviders::Adapters::GetResponse, :no_vcr do
  define_urls(
    lists: 'https://api.getresponse.com/campaigns?perPage=500',
    subscribe: 'https://api.getresponse.com/contacts'
  )

  let(:config_source) { double('config_source', api_key: 'api_key') }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Faraday::Connection' do
      headers = { 'X-Auth-Token' => 'api-key api_key' }
      expect(Faraday).to receive(:new).with(url: 'https://api.getresponse.com/v3', headers: headers).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribe, body: { campaign: { campaignId: '4567456' }, email: 'example@email.com' } do |stub|
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
