describe ServiceProvider::Adapters::VerticalResponse do
  let(:defined_urls) do
    {
      lists: 'https://vrapi.verticalresponse.com/api/v1/lists?access_token=token',
      list: 'https://vrapi.verticalresponse.com/api/v1/lists/4567456?access_token=token',
      subscribe: 'https://vrapi.verticalresponse.com/api/v1/lists/4567456/contacts?access_token=token'
    }
  end

  let(:identity) { double('identity', provider: 'verticalresponse', credentials: { 'token' => 'token' }) }

  include_examples 'service provider'

  describe '#initialize' do
    it 'initializes VerticalResponse::API::OAuth' do
      expect(VerticalResponse::API::OAuth).to receive(:new).with('token').and_call_original
      expect(adapter.client).to be_a VerticalResponse::API::OAuth
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

    let(:body) { 'email=example%40email.com&first_name=FirstName&last_name=LastName' }
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when Contact already exists. error is raised' do
      before do
        allow(adapter.client).to receive(:find_list).and_raise(::VerticalResponse::API::Error, 'Contact already exists.')
      end

      specify { expect { provider.subscribe(email: email, name: name) }.not_to raise_error }
    end
  end

  describe '#batch_subscribe' do
    before { allow_request :get, :list }

    let(:body) { 'contacts[][email]=example1%40email.com&contacts[][email]=example2%40email.com' }
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      provider.batch_subscribe subscribers
      expect(subscribe_request).to have_been_made
    end

    context 'when Contact already exists. error is raised' do
      before do
        allow(adapter.client).to receive(:find_list).and_raise(::VerticalResponse::API::Error, 'Contact already exists.')
      end

      specify { expect { provider.batch_subscribe subscribers }.not_to raise_error }
    end
  end
end
