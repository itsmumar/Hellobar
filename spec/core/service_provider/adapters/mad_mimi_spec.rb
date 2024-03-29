describe ServiceProvider::Adapters::MadMimi do
  let(:defined_urls) do
    {
      lists: 'http://api.madmimi.com/audience_lists/lists.xml',
      subscribe: 'http://api.madmimi.com/audience_lists/4567456/add'
    }
  end

  let(:identity) { double('identity', provider: 'mad_mimi_api', api_key: 'api_key', credentials: { 'username' => 'username' }) }

  include_context 'service provider'

  describe '#initialize' do
    let(:auth) { { access_token: 'token' } }

    it 'initializes MadMimi' do
      expect(MadMimi).to receive(:new).with('username', 'api_key', raise_exceptions: true).and_call_original
      expect(adapter.client).to be_a MadMimi
    end
  end

  describe '#connected?' do
    before { allow_request :get, :lists }

    specify { expect(adapter).to be_connected }

    context 'when an error is raised' do
      before { allow(adapter.client).to receive(:lists).and_raise StandardError }
      specify { expect(adapter).not_to be_connected }
    end
  end

  describe '#lists' do
    before { allow_request :get, :lists, body: 'username=username&api_key=api_key' }

    it 'returns array of id => name' do
      expect(provider.lists).to eql [{ 'id' => list_id.to_s, 'name' => 'List1' }]
    end
  end

  describe '#subscribe' do
    let(:body) { 'username=username&api_key=api_key&name=FirstName%20LastName&email=example%40email.com' }
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
