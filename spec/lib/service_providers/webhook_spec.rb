describe ServiceProviders::Webhook do
  let!(:contact_list) { create(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'post' }) }
  let(:url) { 'http://hellobar.com' }
  let(:webhook) { ServiceProviders::Webhook.new(contact_list: contact_list) }
  let!(:client) { Faraday.new }
  let!(:request) { double('request') }

  before do
    allow(Faraday).to receive(:new) { client }
  end

  context '#client' do
    it 'initializes the client with contact_list.data["webhook_url"]' do
      expect(Faraday).to receive(:new).with(url: url) { client }
      expect(webhook.client).to be_a Faraday::Connection
    end
  end

  context '#subscribe' do
    context 'when webhook_method is POST' do
      before do
        allow(request).to receive(:body=)
        allow(client).to receive(:post).and_yield(request)
      end

      it 'sends only email' do
        expect(request).to receive(:body=).with(email: 'email@email.com', name: nil)
        webhook.subscribe(nil, 'email@email.com')
      end

      it 'sends email and name' do
        expect(request).to receive(:body=).with(email: 'email@email.com', name: 'name')
        webhook.subscribe(nil, 'email@email.com', 'name')
      end

      context 'with custom fields' do
        let(:custom_fields) { %w(phone email name empty gender) }
        let(:body) { { email: 'email@email.com', phone: '+1000000000', name: 'Name', empty: '', gender: 'Male' } }
        let!(:site_element) { create(:site_element, :with_custom_fields, contact_list: contact_list, fields: custom_fields) }

        it 'sends email and all other custom fields' do
          expect(request).to receive(:body=).with(body)
          webhook.subscribe(nil, 'email@email.com', '+1000000000,Name,,Male')
        end

        context 'when fields mismatch settings' do
          let(:custom_fields) { %w(phone email name) }
          let(:body) { { email: 'email@email.com' } }

          it 'sends only email' do
            expect(request).to receive(:body=).with(body)
            webhook.subscribe(nil, 'email@email.com', '+1000000000,Name,,Male')
          end
        end
      end
    end

    context 'when webhook_method is GET' do
      let!(:contact_list) { create(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'get' }) }

      before do
        allow(request).to receive(:params=)
        allow(client).to receive(:get).and_yield(request)
      end

      it 'sends only email' do
        expect(request).to receive(:params=).with(email: 'email@email.com', name: nil)
        webhook.subscribe(nil, 'email@email.com')
      end

      it 'sends email and name' do
        expect(request).to receive(:params=).with(email: 'email@email.com', name: 'Name')
        webhook.subscribe(nil, 'email@email.com', 'Name')
      end

      context 'with custom fields' do
        let(:custom_fields) { %w(phone email name empty gender) }
        let(:params) { { email: 'email@email.com', phone: '+1000000000', name: 'Name', empty: '', gender: 'Male' } }
        let!(:site_element) { create(:site_element, :with_custom_fields, contact_list: contact_list, fields: custom_fields) }

        it 'sends email and all other custom fields' do
          expect(request).to receive(:params=).with(params)
          webhook.subscribe(nil, 'email@email.com', '+1000000000,Name,,Male')
        end

        context 'when fields mismatch settings' do
          let(:custom_fields) { %w(phone email name) }
          let(:params) { { email: 'email@email.com' } }

          it 'sends only email' do
            expect(request).to receive(:params=).with(params)
            webhook.subscribe(nil, 'email@email.com', '+1000000000,Name,,Male')
          end
        end
      end
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) do
      [
        { email: 'email1@email.com' },
        { email: 'email2@email.com', name: 'Name' },
        { email: 'email3@email.com', name: 'Name,+1000000000' }
      ]
    end

    it 'subscribes in batches' do
      expect(webhook).to receive(:subscribe).exactly(3).times
      webhook.batch_subscribe(nil, subscribers)
    end
  end

  describe '#valid?' do
    specify { expect(webhook.valid?).to be_truthy }
  end
end
