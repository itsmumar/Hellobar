describe ServiceProvider::Adapters::ActiveCampaign do
  let(:defined_urls) do
    {
      lists: 'https://example.com/admin/api.php?api_action=list_list&api_key=api_key&api_output=json&ids=all',
      subscribe: 'https://example.com/admin/api.php?api_action=contact_sync&api_key=api_key&api_output=json'
    }
  end

  let(:identity) { double('identity', provider: 'active_campaign', api_key: 'api_key', extra: { 'app_url' => 'example.com' }) }

  include_examples 'service provider'

  describe '.initialize' do
    let(:config) { { api_endpoint: 'https://example.com/admin/api.php', api_key: 'api_key' } }

    it 'initializes ::ActiveCampaign::Client with api_key and api_endpoint' do
      expect(::ActiveCampaign::Client).to receive(:new).with(config)
      adapter
    end
  end

  describe '#connected?' do
    before { allow_request :get, :lists }

    specify { expect(adapter).to be_connected }

    context 'when an error is raised' do
      before { allow(adapter.client).to receive(:list_list).with(ids: 'all').and_raise StandardError }
      specify { expect(adapter).not_to be_connected }
    end
  end

  describe '.lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '.subscribe' do
    let(:body) { { email: 'example@email.com', name: 'FirstName LastName', p: [list_id.to_s], tags: ['id1', 'id2'] } }
    let!(:create_request) { allow_request :post, :subscribe, body: body }

    it 'returns array of id => name' do
      provider.subscribe(email: email, name: name)
      expect(create_request).to have_been_made
    end
  end
end
