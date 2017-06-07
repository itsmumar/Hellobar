describe ServiceProviders::Adapters::ConvertKit do
  let(:defined_urls) do
    {
      lists: 'https://api.convertkit.com/v3/forms?api_secret=api_key',
      subscribe: 'https://api.convertkit.com/v3/forms/4567456/subscribe?api_secret=api_key'
    }
  end

  let(:identity) { double('identity', provider: 'convert_kit', api_key: 'api_key') }

  include_examples 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes ConstantContact::Api' do
      expect(Faraday).to receive(:new).with(url: 'https://api.convertkit.com/v3', params: { api_secret: 'api_key' }, headers: {}).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        body: {
          email: 'example@email.com',
          tags: 'id1,id2',
          fields: { last_name: 'LastName' }, first_name: 'FirstName'
        }
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body }

    it 'sends subscribe request' do
      expect(provider.subscribe(email: 'example@email.com', name: 'FirstName LastName')).to be_a Hash
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe subscribers
    end
  end
end
