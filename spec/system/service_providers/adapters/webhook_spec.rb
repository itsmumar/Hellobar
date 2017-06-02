describe ServiceProviders::Adapters::Webhook do
  define_urls(
    subscribe: 'http://webhook.url/subscribe'
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
    body = { email: 'example@email.com', name: 'FirstName LastName' }
    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    it 'sends subscribe request' do
      provider.subscribe(nil, email: email, name: name)
      expect(subscribe_request).to have_been_made
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
