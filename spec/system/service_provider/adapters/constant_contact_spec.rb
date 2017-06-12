describe ServiceProvider::Adapters::ConstantContact do
  let(:defined_urls) do
    {
      lists: 'https://api.constantcontact.com/v2/lists?api_key=app_key',
      subscribe: 'https://api.constantcontact.com/v2/contacts?action_by=ACTION_BY_VISITOR&api_key=app_key',
      no_double_optin: 'https://api.constantcontact.com/v2/contacts?api_key=app_key',
      update: 'https://api.constantcontact.com/v2/contacts/{id}?action_by=ACTION_BY_VISITOR&api_key=app_key',
      contact: 'https://api.constantcontact.com/v2/contacts?api_key=app_key&email=example@email.com',
      batch_subscribe: 'https://api.constantcontact.com/v2/activities/addcontacts?api_key=app_key'
    }
  end

  let(:identity) { double('identity', provider: 'constantcontact', credentials: { 'token' => 'token' }) }

  include_examples 'service provider'

  before do
    ServiceProvider::Adapters::ConstantContact.configure do |config|
      config.app_key = 'app_key'
    end
  end

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Faraday::Connection' do
      headers = { authorization: 'Bearer token' }
      params = { api_key: 'app_key' }
      url = 'https://api.constantcontact.com/v2'
      expect(Faraday).to receive(:new).with(url: url, params: params, headers: headers).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        email_addresses: [{ email_address: 'example@email.com' }],
        first_name: 'FirstName',
        last_name: 'LastName',
        lists: [{ id: list_id }]
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    let(:subscribe) { provider.subscribe(email: email, name: name) }

    it 'sends subscribe request' do
      subscribe
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

    context 'when Faraday::Conflict' do
      before { allow_request :post, :subscribe, body: body, response: { status: 409 } }
      before { allow_request :get, :contact }

      let!(:update_request) { allow_request :put, :update, body: body.merge(id: 1) }

      it 'updates subscriber' do
        subscribe
        expect(update_request).to have_been_made
      end

      context 'when again Faraday::Conflict' do
        before { allow_request :post, :subscribe, body: body, response: { status: 409 } }
        before { allow_request :get, :contact }

        let!(:update_request) { allow_request :put, :update, body: body.merge(id: 1), response: { status: 409 } }

        it 'returns nothing' do
          expect(subscribe).to be_nil
          expect(update_request).to have_been_made
        end
      end
    end

    context 'when Faraday::BadRequest' do
      let(:error_message) { '' }

      context 'when message is "not a valid email address"' do
        before { allow_request :post, :subscribe, body: body, response: { status: 400, body: error_message } }

        let(:error_message) { 'not a valid email address' }

        it 'returns nothing' do
          expect(subscribe).to be_nil
        end
      end

      context 'when message is "not be opted in using"' do
        before { allow(contact_list).to receive(:double_optin).and_return(false) }
        before { allow_request :post, :no_double_optin, body: body, response: { status: 400, body: error_message } }

        let(:error_message) { 'not be opted in using' }
        let!(:retry_request) { allow_request :post, :subscribe, body: body }

        it 're-tries with double optin' do
          subscribe
          expect(retry_request).to have_been_made
        end
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
