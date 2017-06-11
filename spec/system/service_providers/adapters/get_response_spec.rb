describe ServiceProviders::Adapters::GetResponse do
  let(:defined_urls) do
    {
      lists: 'https://api.getresponse.com/v3/campaigns?perPage=500',
      contacts: 'https://api.getresponse.com/v3/contacts?fields=contactId,email&page=0&perPage=20&sort%5BcreatedOn%5D=desc',
      contact: 'https://api.getresponse.com/v3/contacts/1',
      subscribe: 'https://api.getresponse.com/v3/contacts'
    }
  end

  let(:identity) { double('identity', provider: 'get_response_api', api_key: 'api_key') }

  include_examples 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Faraday::Connection' do
      headers = { 'X-Auth-Token' => 'api-key api_key' }
      expect(Faraday).to receive(:new).with(url: 'https://api.getresponse.com/v3', headers: headers, params: {}).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    before { allow_request :get, :contacts }
    before { allow_request :post, :contact }

    let(:body) { { campaign: { campaignId: '4567456' }, email: 'example@email.com', name: 'FirstName LastName' } }
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    before { allow(contact_list).to receive(:subscribers).and_return([email: 'example@email.com']) }

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe list_id, subscribers
    end
  end
end
