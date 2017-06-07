describe ServiceProviders::Adapters::VerticalResponseForm do
  let(:defined_urls) do
    {
      subscribe: 'http://oi.vresp.com?fid=e831f8d796'
    }
  end

  let(:identity) { double('identity', provider: 'vertical_response') }
  include_examples 'service provider'
  let(:contact_list) { create(:contact_list, :vertical_response) }

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
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
