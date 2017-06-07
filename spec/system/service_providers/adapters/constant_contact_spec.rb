describe ServiceProviders::Adapters::ConstantContact do
  let(:defined_urls) do
    {
      lists: 'https://api.constantcontact.com/v2/lists?api_key=app_key',
      list: 'https://api.constantcontact.com/v2/lists/4567456?api_key=app_key',
      subscribe: 'https://api.constantcontact.com/v2/contacts?action_by=ACTION_BY_VISITOR&api_key=app_key',
      batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key'
    }
  end

  let(:identity) { double('identity', provider: 'constantcontact', credentials: { 'token' => 'token' }) }

  include_examples 'service provider'

  before do
    ServiceProviders::Adapters::ConstantContact.configure do |config|
      config.app_key = 'app_key'
    end
  end

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes ConstantContact::Api' do
      expect(ConstantContact::Api).to receive(:new).with('app_key', 'token').and_call_original
      expect(adapter.client).to be_a ConstantContact::Api
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    before { allow_request :get, :list }

    let(:body) do
      {
        email_addresses: [{ email_address: 'example@email.com' }],
        first_name: 'FirstName',
        last_name: 'LastName',
        lists: [{ id: list_id, name: 'List1' }]
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    let(:subscribe) { provider.subscribe(email: email, name: name) }

    it 'sends subscribe request' do
      expect(subscribe).to be_a ::ConstantContact::Components::Contact
      expect(subscribe_request).to have_been_made
    end

    context 'when Unautorized' do
      let(:response) { { status: 401 } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body, response: response }

      it 'calls identity.destroy_and_notify_user' do
        expect(identity).to receive(:destroy_and_notify_user)
        subscribe
      end
    end
  end

  describe '#batch_subscribe' do
    let(:body) do
      { import_data: [
        { first_name: 'FirstName', last_name: 'LastName', email_addresses: ['example1@email.com'] },
        { first_name: 'FirstName', last_name: 'LastName', email_addresses: ['example2@email.com'] }
      ], lists: [list_id], column_names: ['E-Mail', 'First Name', 'Last Name'] }
    end

    let(:subscribers) { [{ email: 'example1@email.com', name: name }, { email: 'example2@email.com', name: name }] }
    let!(:batch_subscribe_request) { allow_request :post, :batch_subscribe, body: body }

    it 'calls #subscribe for each subscriber' do
      provider.batch_subscribe subscribers
      expect(batch_subscribe_request).to have_been_made
    end
  end
end
