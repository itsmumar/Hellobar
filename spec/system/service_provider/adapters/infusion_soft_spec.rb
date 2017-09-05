describe ServiceProvider::Adapters::InfusionsoftOauth do
  let(:defined_urls) do
    {
      subscribe: 'https://api.infusionsoft.com/crm/rest/v1/contacts',
      campaigns: 'https://api.infusionsoft.com/crm/rest/v1/campaigns',
      campaign: 'https://api.infusionsoft.com/crm/rest/v1/campaigns/{campaign_id}?optional_properties=sequences',
      add_to_campaign: 'https://api.infusionsoft.com/crm/rest/v1/campaigns/{campaign_id}/sequences/{sequence_id}/contacts/{contact_id}',
    }
  end

  let(:identity) { double('identity', provider: 'infusion_soft', credentials: { 'token' => 'token' }) }

  include_context 'service provider'

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      headers = { 'Authorization': 'Bearer token' }

      expect(Faraday).to receive(:new)
       .with(url: 'https://api.infusionsoft.com/crm/rest/v1', params: {}, headers: headers)
       .and_call_original

      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#connected?' do
    before { allow_request :get, :campaigns }

    specify { expect(adapter).to be_connected }

    context 'when an error is raised' do
      before { allow(adapter).to receive(:lists).and_raise StandardError }
      specify { expect(adapter).not_to be_connected }
    end
  end

  describe '#lists' do
    before { allow_request :get, :campaigns }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    let(:body) { {} }

    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    before do
      allow_request :get, :campaign
      allow_request :post, :add_to_campaign
    end

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
