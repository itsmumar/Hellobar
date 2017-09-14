describe ServiceProvider::Adapters::VerticalResponseForm do
  let(:defined_urls) do
    {
      subscribe: 'http://oi.vresp.com?fid=e831f8d796'
    }
  end

  include_context 'service provider'

  let(:contact_list) { create(:contact_list, :vertical_response) }
  let(:identity) { create :identity, :vertical_response, contact_lists: [contact_list] }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        'email_address' => 'example@email.com',
        'first_name' => 'FirstName',
        'last_name' => 'LastName'
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when error is occured' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 404, body: '{}') }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end
    end
  end
end
