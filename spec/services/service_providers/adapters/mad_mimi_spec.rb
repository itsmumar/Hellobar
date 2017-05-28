describe ServiceProviders::Adapters::MadMimi do
  define_urls(
    lists: 'http://api.madmimi.com/audience_lists/lists.xml',
    subscribe: 'http://api.madmimi.com/audience_lists/4567456/add',
    batch_subscribe: 'http://api.madmimi.com/audience_members'
  )

  let(:config_source) { double('config_source', api_key: 'api_key', credentials: { 'username' => 'username' }) }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

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
      expect(adapter.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    allow_request :post, :subscribe, body: 'username=username&api_key=api_key&email=example%40email.com' do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      adapter.subscribe(list_id, email: 'example@email.com')
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
      adapter.batch_subscribe 'list_id', subscribers
      expect(batch_subscribe_request).to have_been_made
    end
  end
end
