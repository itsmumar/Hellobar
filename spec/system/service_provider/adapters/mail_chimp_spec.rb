describe ServiceProvider::Adapters::MailChimp do
  let(:defined_urls) do
    {
      lists: 'http://apiendpoint/3.0/lists?count=100',
      subscribe: 'http://apiendpoint/3.0/lists/57afe96172/members'
    }
  end

  let(:identity) do
    double('identity',
      provider: 'mailchimp',
      extra: { 'metadata' => { 'api_endpoint' => 'http://apiendpoint' } },
      credentials: { 'token' => 'api_key' })
  end

  include_context 'service provider'

  let(:list_id) { '57afe96172' }

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes Gibbon::Request' do
      expect(Gibbon::Request).to receive(:new).with(api_key: 'api_key', api_endpoint: 'http://apiendpoint').and_call_original
      expect(adapter.client).to be_a Gibbon::Request
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
        email_address: email,
        status: 'pending',
        merge_fields: { FNAME: first_name, LNAME: last_name }
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json }

    let(:subscribe) { provider.subscribe(email: email, name: name) }

    it 'sends subscribe request' do
      subscribe
      expect(subscribe_request).to have_been_made
    end

    context 'when double optin is disabled' do
      let(:contact_list) { create(:contact_list, :with_tags, list_id: list_id, double_optin: false) }
      let(:single_optin_body) { body.merge(status: 'subscribed') }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: single_optin_body.to_json }

      it 'sends :subscribed status' do
        subscribe
        expect(subscribe_request).to have_been_made
      end
    end

    context 'when API key is invalid' do
      let(:response) { { status: 401, body: { title: 'API Key Invalid' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        subscribe
      end
    end

    context 'when Resource Not Found' do
      let(:response) { { status: 404, body: { title: 'Resource Not Found' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        subscribe
      end
    end

    context 'when Invalid Resource' do
      let(:response) { { status: 400, body: { title: 'Invalid Resource' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'raises ServiceProvider::InvalidSubscriberError' do
        expect { subscribe }.to raise_error(ServiceProvider::InvalidSubscriberError)
      end
    end

    context 'when Member Exists' do
      let(:response) { { status: 400, body: { title: 'Member Exists' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'does not raise error' do
        expect { subscribe }.not_to raise_error
      end
    end

    context 'when Net::ReadTimeout' do
      let(:response) { { status: 400, body: { title: 'Net::ReadTimeout' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'does not raise error' do
        expect { subscribe }.not_to raise_error
      end
    end

    context 'with another exception' do
      let(:response) { { status: 400, body: { title: 'Unknown' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body.to_json, response: response }

      it 'raises error' do
        expect { subscribe }.to raise_error(Gibbon::MailChimpError)
      end
    end

    context 'when could not connect' do
      let(:client) { double('Gibbon::Request') }

      before do
        allow(Gibbon::Request).to receive(:new).and_return(client)
        allow(client)
          .to receive(:lists)
          .and_raise(Gibbon::MailChimpError, 'Net::OpenTimeout')
          .once
      end

      it 'raises ServiceProvider::ConnectionProblemError' do
        expect { subscribe }.to raise_error(ServiceProvider::ConnectionProblemError)
      end
    end
  end
end
