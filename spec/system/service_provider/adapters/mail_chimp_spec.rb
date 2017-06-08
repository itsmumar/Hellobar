describe ServiceProvider::Adapters::MailChimp do
  let(:defined_urls) do
    {
      lists: 'http://apiendpoint/3.0/lists?count=100',
      subscribe: 'http://apiendpoint/3.0/lists/57afe96172/members',
      batch_subscribe: 'http://apiendpoint/3.0/batches'
    }
  end

  let(:identity) do
    double('identity',
      provider: 'mailchimp',
      extra: { 'metadata' => { 'api_endpoint' => 'http://apiendpoint' } },
      credentials: { 'token' => 'api_key' })
  end

  include_examples 'service provider'

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
        email_address: 'example@email.com',
        status: 'pending',
        merge_fields: { FNAME: 'FirstName', LNAME: 'LastName' }
      }.to_json
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    let(:subscribe) { provider.subscribe(email: email, name: name) }

    it 'sends subscribe request' do
      subscribe
      expect(subscribe_request).to have_been_made
    end

    context 'when API key is invalid' do
      let(:response) { { status: 401, body: { title: 'API Key Invalid' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body, response: response }

      it 'calls identity.destroy_and_notify_user' do
        expect(identity).to receive(:destroy_and_notify_user)
        subscribe
      end
    end

    context 'when Resource Not Found' do
      let(:response) { { status: 404, body: { title: 'Resource Not Found' }.to_json } }
      let!(:subscribe_request) { allow_request :post, :subscribe, body: body, response: response }

      it 'calls identity.destroy_and_notify_user' do
        expect(identity).to receive(:destroy_and_notify_user)
        subscribe
      end
    end
  end

  describe '#batch_subscribe' do
    let(:body) do
      {
        operations: [
          { method: 'POST', path: "lists/#{ list_id }/members", body: '{"email_address":"example1@email.com","status":"pending"}' },
          { method: 'POST', path: "lists/#{ list_id }/members", body: '{"email_address":"example2@email.com","status":"pending"}' }
        ]
      }
    end
    let!(:batch_subscribe_request) { allow_request :post, :batch_subscribe, body: body }

    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'sends post request to /audience_members' do
      provider.batch_subscribe subscribers
      expect(batch_subscribe_request).to have_been_made
    end
  end
end
