describe ServiceProviders::Adapters::ActiveCampaign do
  define_urls(
    lists: 'https://example.com/admin/api.php?api_action=list_list&api_key=api_key&api_output=json&ids=all',
    subscribe: 'https://example.com/admin/api.php?api_action=contact_sync&api_key=api_key&api_output=json'
  )

  let(:identity) { double('identity', provider: 'active_campaign', api_key: 'api_key', extra: { 'app_url' => 'example.com' }) }

  include_examples 'service provider'

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
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '.subscribe' do
    body = { email: 'example@email.com', name: 'FirstName LastName', p: ['1'], tags: ['id1', 'id2'] }
    allow_request :post, :subscribe, body: body do |stub|
      let!(:create_request) { stub }
    end

    it 'returns array of id => name' do
      provider.subscribe(1, email: email, name: name)
      expect(create_request).to have_been_made
    end
  end

  describe '.batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe 'list_id', subscribers
    end
  end
end
