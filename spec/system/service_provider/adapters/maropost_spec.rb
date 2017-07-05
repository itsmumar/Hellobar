describe ServiceProvider::Adapters::Maropost do
  let(:defined_urls) do
    {
      lists: 'http://maropost.url/accounts/12345/lists.json?auth_token=api_key&no_counts=true',
      tags: 'http://maropost.url/accounts/12345/tags.json?auth_token=api_key&no_counts=true',
      subscribe: 'http://maropost.url/accounts/12345/lists/4567456/contacts.json?auth_token=api_key'
    }
  end

  let(:identity) { double('identity', provider: 'maropost', api_key: 'api_key', credentials: { 'username' => '12345' }) }

  include_examples 'service provider'

  before do
    ServiceProvider::Adapters::Maropost.configure do |config|
      config.url = 'http://maropost.url'
    end
  end

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      params = { auth_token: 'api_key' }
      expect(Faraday).to receive(:new).with(url: 'http://maropost.url/accounts/12345', params: params, headers: {}).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#connected?' do
    before { allow_request :get, :lists }

    specify { expect(adapter).to be_connected }

    context 'when an error is raised' do
      before { allow(adapter.client).to receive(:get).and_raise StandardError }
      specify { expect(adapter).not_to be_connected }
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#tags' do
    before { allow_request :get, :tags }

    it 'returns array of id => name' do
      expect(provider.tags).to eql [{ 'name' => 'Tag1', 'id' => 1 }]
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        contact: {
          email: 'example@email.com',
          subscribe: true,
          remove_from_dnm: true,
          add_tags: ['id1', 'id2'],
          first_name: 'FirstName',
          last_name: 'LastName'
        }
      }.to_json
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when request is unsuccessful' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 504, body: '{}') }

      it 'sends subscribe request' do
        expect { provider.subscribe(email: email, name: name) }
          .to raise_error(Faraday::ClientError)
      end
    end
  end
end
