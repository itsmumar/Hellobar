describe ServiceProviders::Adapters::Drip do
  define_urls(
    lists: 'https://api.getdrip.com/v2/account_id/campaigns?status=active',
    subscribe: 'https://api.getdrip.com/v2/account_id/campaigns/4567456/subscribers',
    batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key'
  )

  let(:identity) { double('identity', provider: 'drip', credentials: { 'token' => 'token' }, extra: { 'account_id' => 'account_id' }) }

  include_examples 'service provider'

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
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        subscribers: [
          {
            new_email: 'example@email.com',
            tags: ['id1', 'id2'],
            custom_fields: {
              name: 'FirstName LastName',
              fname: 'FirstName',
              lname: 'LastName'
            },
            double_optin: true,
            email: 'example@email.com'
          }
        ]
      }.to_json
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:body) do
      {
        import_data: [
          { email_addresses: ['example1@email.com'] }, { email_addresses: ['example2@email.com'] }
        ],
        lists: [list_id],
        column_names: ['E-Mail', 'First Name', 'Last Name']
      }
    end
    let!(:batch_subscribe_request) { allow_request :post, :batch_subscribe, body: body }
    let(:subscribers) { [{ email: 'example1@email.com', double_optin: true }, { email: 'example2@email.com', double_optin: true }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber)
      end
      provider.batch_subscribe list_id, subscribers
    end
  end
end
