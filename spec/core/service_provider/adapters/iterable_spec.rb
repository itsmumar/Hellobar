describe ServiceProvider::Adapters::Iterable do
  let(:identity) { build_stubbed :identity, :iterable }
  let(:api_key) { identity.api_key }
  let(:api_url) { 'https://api.iterable.com/api' }
  let(:list_id) { 49804 }
  let(:list_name) { 'Hello Bar Contacts' }

  let(:defined_urls) do
    {
      lists: "#{ api_url }/lists?api_key=#{ api_key }",
      subscribe: "#{ api_url }/lists/subscribe?api_key=#{ api_key }"
    }
  end

  let(:contact_list) { create :contact_list, list_id: list_id }
  let(:provider) { ServiceProvider.new(identity, contact_list) }
  let(:adapter) { provider.adapter }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(Faraday).to receive(:new)
        .with(url: api_url, params: { api_key: api_key }, headers: {})
        .and_call_original

      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#connected?' do
    before { allow_request :get, :lists }

    specify { expect(adapter).to be_connected }

    context 'when an error is raised' do
      before do
        allow(adapter.client).to receive(:get)
          .with('lists')
          .and_raise StandardError
      end

      specify { expect(adapter).not_to be_connected }
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id, 'name' => list_name }]
    end
  end

  describe '#subscribe' do
    let(:email) { 'example@email.com' }
    let(:first_name) { 'FirstName' }
    let(:last_name) { 'LastName' }
    let(:name) { "#{ first_name } #{ last_name }" }
    let(:body) do
      {
        listId: list_id,
        subscribers: [{
          email: email,
          dataFields: {
            firstName: first_name,
            lastName: last_name
          }
        }]
      }
    end

    it 'sends subscribe request' do
      subscribe_request = allow_request :post, :subscribe, body: body.to_json

      provider.subscribe(email: email, name: name)

      expect(subscribe_request).to have_been_made
    end
  end
end
