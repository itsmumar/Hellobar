describe ServiceProvider::Adapters::Klaviyo do
  let(:defined_urls) do
    {
      lists: 'https://a.klaviyo.com/api/v2/lists?api_key=api_key',
      subscribe: "https://a.klaviyo.com/api/v2/list/#{ list_id }/subscribe?api_key=api_key"
    }
  end

  let(:identity) { double('identity', provider: 'klaviyo', api_key: 'api_key') }

  include_context 'service provider'

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      params = { api_key: 'api_key' }
      expect(Faraday).to receive(:new).with(url: 'https://a.klaviyo.com/api/v2', params: params, headers: {}).and_call_original
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
      expect(provider.lists).to eql [{ 'id' => 'abcDEF', 'name' => 'my list' }]
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        profiles: [{
          email: 'example@email.com',
          first_name: 'FirstName',
          last_name: 'LastName'
        }]
      }.to_json
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when status is 504' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 504, body: '{}') }

      it 'raises Faraday::ClientError' do
        expect { provider.subscribe(email: email, name: name) }
          .to raise_error(Faraday::ClientError)
      end
    end

    context 'when status is 401' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 404, body: '{}') }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end
    end
  end
end
