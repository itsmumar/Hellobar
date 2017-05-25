describe ServiceProviders::Adapters::ConvertKit do
  define_urls(
    lists: 'https://api.convertkit.com/forms?api_secret=api_key',
    subscribe: 'https://api.convertkit.com/forms/4567456/subscribe?api_secret=api_key',
    batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key'
  )

  let(:config_source) { double('config_source', api_key: 'api_key') }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes ConstantContact::Api' do
      expect(Faraday).to receive(:new).with(url: 'https://api.convertkit.com/v3').and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribe, body: { body: { email: 'example@email.com', 'tags': '' } } do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      expect(adapter.subscribe(list_id, email: 'example@email.com')).to be_a Hash
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    allow_request :post, :batch_subscribe, body: { import_data: [{ email_addresses: ['example1@email.com'] }, { email_addresses: ['example2@email.com'] }], lists: [4567456], column_names: ['E-Mail', 'First Name', 'Last Name'] } do |stub|
      let(:batch_subscribe_request) { stub }
    end
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber)
      end
      adapter.batch_subscribe 'list_id', subscribers
    end
  end
end
