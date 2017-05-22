describe ServiceProviders::Adapters::ActiveCampaign do
  define_urls(
    lists: 'https://example.com/admin/api.php?api_action=list_list&api_key=api_key&api_output=json&ids=all',
    subscribe: 'https://example.com/admin/api.php?api_action=contact_sync&api_key=api_key&api_output=json'
  )

  let(:config_source) { double('config_source', api_key: 'api_key', extra: { 'app_url' => 'example.com' }) }
  let(:adapter) { described_class.new(config_source) }

  describe '.initialize' do
    let(:config) { { api_endpoint: 'https://example.com/admin/api.php', api_key: 'api_key' } }

    it 'initializes ::ActiveCampaign::Client with api_key and api_endpoint' do
      expect(::ActiveCampaign::Client).to receive(:new).with(config)
      adapter
    end
  end

  describe '.lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => '1', 'name' => 'List1' }, { 'id' => '2', 'name' => 'List2' }]
    end
  end

  describe '.subscribe' do
    allow_request :post, :subscribe, body: 'email=example%40email.com&p%5B1%5D=1' do |stub|
      let!(:create_request) { stub }
    end

    it 'returns array of id => name' do
      contact = { email: 'example@email.com' }
      expect { adapter.subscribe(1, contact) }.not_to raise_error
      expect(create_request).to have_been_made
    end
  end

  describe '.batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber)
      end
      adapter.batch_subscribe 'list_id', subscribers
    end
  end
end
