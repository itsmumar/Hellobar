describe ServiceProviders::Adapters::Webhook do
  define_urls(
    subscribe: 'http://webhook.url/subscribe',
    subscribe_get: 'http://webhook.url/subscribe?email=example@email.com&name=FirstName%20LastName'
  )

  let(:identity) { double('identity', provider: 'webhook') }
  include_examples 'service provider'

  let(:contact_list) do
    create(:contact_list, data: { 'webhook_url' => 'http://webhook.url/subscribe', 'webhook_method' => 'POST' })
  end

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(Faraday).to receive(:new).with(url: 'http://webhook.url/subscribe', params: {}, headers: {}).and_call_original
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    let(:body) { { email: 'example@email.com', name: 'FirstName LastName' } }

    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends email and name' do
      provider.subscribe(nil, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end

    context 'with get request' do
      let!(:subscribe_request) { allow_request :get, :subscribe_get }

      let(:contact_list) do
        create(:contact_list, data: { 'webhook_url' => 'http://webhook.url/subscribe', 'webhook_method' => 'GET' })
      end

      it 'sends email and name' do
        provider.subscribe(nil, email: email, name: name)
        expect(subscribe_request).to have_been_made
      end
    end

    context 'with email only' do
      let(:body) { { email: 'example@email.com', name: nil } }

      it 'sends email request' do
        provider.subscribe(nil, email: email)
        expect(subscribe_request).to have_been_made
      end
    end

    context 'with custom fields' do
      let(:custom_fields) { %w[phone email name empty gender] }
      let(:body) { { email: email, phone: '+1000000000', name: 'Name', empty: '', gender: 'Male' } }
      let!(:site_element) { create(:site_element, :with_custom_fields, contact_list: contact_list, fields: custom_fields) }

      it 'sends email and all other custom fields' do
        provider.subscribe(nil, email: email, name: '+1000000000,Name,,Male')
        expect(subscribe_request).to have_been_made
      end

      context 'when fields mismatch settings' do
        let(:custom_fields) { %w[phone email name] }
        let(:body) { { email: email } }

        it 'sends only email' do
          provider.subscribe(nil, email: email, name: '+1000000000,Name,,Male')
          expect(subscribe_request).to have_been_made
        end
      end
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(nil, subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe nil, subscribers
    end
  end
end
