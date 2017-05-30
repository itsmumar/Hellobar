describe ServiceProviders::Adapters::MadMimi, :no_vcr do
  define_urls(
    lists: 'http://api.madmimi.com/audience_lists/lists.xml',
    subscribe: 'http://api.madmimi.com/audience_lists/4567456/add',
    batch_subscribe: 'http://api.madmimi.com/audience_members'
  )

  let(:identity) { double('identity', provider: 'mad_mimi', api_key: 'api_key', credentials: { 'username' => 'username' }) }

  include_examples 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes MadMimi' do
      expect(MadMimi).to receive(:new).with('username', 'api_key', raise_exceptions: true).and_call_original
      expect(adapter.client).to be_a MadMimi
    end
  end

  describe '#lists' do
    allow_request :get, :lists, body: 'username=username&api_key=api_key'

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    body = 'username=username&api_key=api_key&name=FirstName%20LastName&email=example%40email.com'
    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    body = 'username=username&api_key=api_key&csv_file=email%2Cadd_list%0Aexample1%40email.com%2Clist_id%0Aexample2%40email.com%2Clist_id%0A'
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
