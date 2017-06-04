describe ServiceProviders::Adapters::MyEmma do
  let(:defined_urls) do
    {
      form: 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a',
      subscribe: 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    }
  end

  let(:identity) { double('identity', provider: 'my_emma') }
  include_examples 'service provider'
  let(:contact_list) { create(:contact_list, :my_emma) }

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
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
