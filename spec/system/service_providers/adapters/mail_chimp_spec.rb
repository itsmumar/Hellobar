describe ServiceProviders::Adapters::MailChimp do
  define_urls(
    lists: 'http://apiendpoint/3.0/lists?count=100',
    subscribe: 'http://apiendpoint/3.0/lists/57afe96172/members',
    batch_subscribe: 'http://apiendpoint/3.0/batches'
  )

  let(:identity) { double('identity', provider: 'mailchimp', extra: { 'metadata' => { 'api_endpoint' => 'http://apiendpoint' } }, credentials: { 'token' => 'api_key' }) }

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
    allow_request :get, :lists

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribe, body: '{"email_address":"example@email.com","status":"pending","merge_fields":{"FNAME":"FirstName","LNAME":"LastName"}}' do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    body = {
      operations: [
        { method: 'POST', path: 'lists/list_id/members', body: '{"email_address":"example1@email.com","status":"pending"}' },
        { method: 'POST', path: 'lists/list_id/members', body: '{"email_address":"example2@email.com","status":"pending"}' }
      ]
    }

    allow_request :post, :batch_subscribe, body: body do |stub|
      let(:batch_subscribe_request) { stub }
    end

    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'sends post request to /audience_members' do
      provider.batch_subscribe 'list_id', subscribers
      expect(batch_subscribe_request).to have_been_made
    end
  end
end
