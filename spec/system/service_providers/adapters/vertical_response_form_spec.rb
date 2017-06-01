describe ServiceProviders::Adapters::VerticalResponseForm do
  define_urls(
    subscribe: 'http://oi.vresp.com?fid=e831f8d796'
  )

  let(:identity) { double('identity', provider: 'vertical_response') }
  include_examples 'service provider'
  let(:contact_list) { create(:contact_list, :embed_vertical_response) }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    body = {
      'email_address' => 'example@email.com',
      'first_name' => 'FirstName',
      'last_name' => 'LastName'
    }

    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
