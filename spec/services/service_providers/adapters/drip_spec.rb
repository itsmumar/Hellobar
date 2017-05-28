describe ServiceProviders::Adapters::Drip, :no_vcr do
  define_urls(
    lists: 'https://api.getdrip.com/v2/account_id/campaigns?status=active',
    subscribe: 'https://api.getdrip.com/v2/account_id/campaigns/4567456/subscribers',
    batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key'
  )

  let(:config_source) { double('config_source', credentials: { 'token' => 'token' }, extra: { 'account_id' => 'account_id' }) }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Drip::Client' do
      expect(Drip::Client).to receive(:new).with(access_token: 'token', account_id: 'account_id').and_call_original
      expect(adapter.client).to be_a Drip::Client
    end
  end

  describe '#lists' do
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(adapter.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribe, body: '{"subscribers":[{"new_email":"example@email.com","tags":[],"double_optin":true,"email":"example@email.com"}]}' do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      adapter.subscribe(list_id, email: 'example@email.com')
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
        expect(adapter).to receive(:subscribe).with('list_id', subscriber, false)
      end
      adapter.batch_subscribe 'list_id', subscribers, false
    end
  end
end
