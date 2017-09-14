describe ServiceProvider::Adapters::MyEmma do
  let(:defined_urls) do
    {
      form: 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a',
      subscribe: 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    }
  end

  include_context 'service provider'

  let(:contact_list) { create(:contact_list, :my_emma) }
  let(:identity) { create :identity, :my_emma, contact_lists: [contact_list] }

  before { allow_request :get, :form }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        'Submit' => 'Submit',
        'email' => 'example@email.com',
        'invalid_signup' => '',
        'prev_member_email' => '',
        'source' => ''
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'when error is occured' do
      before { stub_request(:post, url_for_request(:subscribe)).and_return(status: 404, body: '{}') }

      it 'calls DestroyIdentity' do
        expect(DestroyIdentity).to receive_service_call.with(identity, notify_user: true)
        expect { provider.subscribe(email: email, name: name) }.not_to raise_error
      end
    end
  end
end
