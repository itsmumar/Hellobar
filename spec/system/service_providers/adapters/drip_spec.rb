describe ServiceProviders::Adapters::Drip do
  let(:defined_urls) do
    {
      tags: 'https://api.getdrip.com/v2/account_id/tags',
      lists: 'https://api.getdrip.com/v2/account_id/campaigns?status=active',
      subscribe: 'https://api.getdrip.com/v2/account_id/campaigns/4567456/subscribers',
      batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key',
      subscribe_without_list: 'https://api.getdrip.com/v2/account_id/subscribers'
    }
  end

  let(:identity) { double('identity', provider: 'drip', credentials: { 'token' => 'token' }, extra: { 'account_id' => 'account_id' }) }

  include_examples 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Drip::Client' do
      expect(Drip::Client).to receive(:new).with(access_token: 'token', account_id: 'account_id').and_call_original
      expect(adapter.client).to be_a Drip::Client
    end
  end

  describe '#tags' do
    before { allow_request :get, :tags }

    it 'returns array of id => name' do
      expect(provider.tags).to eql [{ 'id' => 'Tag1', 'name' => 'Tag1' }]
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

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
            double_optin: true,
            custom_fields: {
              name: 'FirstName LastName',
              fname: 'FirstName',
              lname: 'LastName'
            },
            email: 'example@email.com'
          }
        ]
      }.to_json
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when list_id is nil' do
      let(:list_id) { nil }

      let!(:subscribe_request) { allow_request :post, :subscribe_without_list, body: body }

      it 'adds subscriber to the global account list' do
        provider.subscribe(email: email, name: name)
        expect(subscribe_request).to have_been_made
      end
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
      provider.batch_subscribe subscribers
    end
  end
end
