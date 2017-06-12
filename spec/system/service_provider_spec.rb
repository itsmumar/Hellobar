describe ServiceProvider do
  let(:adapter_class) { Class.new(ServiceProvider::Adapters::Base) }
  let(:adapter) { adapter_class.new(double('client')) }
  let(:identity) { create :identity, provider: 'foo' }
  let(:contact_list) { create :contact_list, :with_tags }
  let(:provider) { described_class.new(identity, contact_list) }

  let(:list_id) { contact_list.data['remote_id'] }

  before { allow(adapter_class).to receive(:name).and_return('Foo') }
  before { allow(adapter_class).to receive(:new).and_return(adapter) }
  before { ServiceProvider::Adapters.register 'foo', adapter_class }
  after { ServiceProvider::Adapters.registry.delete(:foo) }

  describe '.configure' do
    before do
      adapter_class.configure do |config|
        config.api_key = 1
      end
    end

    it 'yields config' do
      expect(adapter_class.config.api_key).to eq 1
    end
  end

  describe '#initialize' do
    it 'instantiates the adapter using provider name' do
      expect(provider.adapter).to be_a adapter_class
    end
  end

  describe '#name' do
    it 'is adapter.key' do
      expect(provider.name).to eq adapter.key
    end
  end

  describe '#lists' do
    before { allow(adapter).to receive(:lists).and_return(['1' => 'List1']) }

    it 'returns array of id => name' do
      expect(provider.lists).to eq ['1' => 'List1']
    end

    context 'when exception is raised' do
      let(:options) do
        {
          extra: {
            identity_id: identity.id,
            contact_list_id: contact_list.id,
            arguments: [],
            remote_list_id: list_id,
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end
      before { allow(Rails.env).to receive(:test?).and_return(false) }

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:lists).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect {
          provider.lists
        }.not_to raise_error
      end
    end
  end

  describe '#subscribe' do
    let(:params) { { email: 'email@example.com', name: 'FirstName LastName', tags: [], double_optin: false } }
    let(:contact_list) { create(:contact_list, double_optin: false) }
    let(:provider) { described_class.new(identity, contact_list) }

    let(:subscribe) { provider.subscribe(email: 'email@example.com', name: 'FirstName LastName') }

    it 'calls adapter' do
      expect(adapter).to receive(:subscribe).with(list_id, params)
      subscribe
    end

    context 'when contact_list.tags is not empty' do
      let(:contact_list) { create(:contact_list, :with_tags) }
      let(:provider) { described_class.new(identity, contact_list) }
      let(:params) { { email: 'email@example.com', name: 'FirstName LastName', tags: ['id1', 'id2'], double_optin: true } }

      it 'passes tags to adapter' do
        expect(adapter).to receive(:subscribe).with(list_id, params)
        subscribe
      end

      context 'with empty tag' do
        before { contact_list.data['tags'] = ['', ' ', 'not empty'] }

        it 'does not send empty tag' do
          expect(adapter).to receive(:subscribe).with(list_id, hash_including(tags: ['not empty']))
          subscribe
        end
      end
    end

    context 'with not a valid email' do
      let(:subscribe) { provider.subscribe(email: 'not@valid@example.com', name: 'FirstName LastName') }

      it 'does not call adapter' do
        expect(adapter).not_to receive(:subscribe)
        subscribe
      end
    end

    context 'when exception is raised' do
      let(:options) do
        {
          extra: {
            identity_id: identity.id,
            contact_list_id: contact_list.id,
            remote_list_id: list_id,
            arguments: [email: 'email@example.com', name: 'FirstName LastName'],
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end
      before { allow(Rails.env).to receive(:test?).and_return(false) }

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:subscribe).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect { subscribe }.not_to raise_error
      end
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [email: 'email@example.com', name: 'FirstName LastName'] }
    let(:contact_list) { create(:contact_list, :with_tags, double_optin: false) }
    let(:provider) { described_class.new(identity, contact_list) }

    let(:batch_subscribe) { provider.batch_subscribe(subscribers) }

    it 'calls adapter' do
      expect(adapter).to receive(:batch_subscribe).with(list_id, subscribers, double_optin: false)
      batch_subscribe
    end

    context 'with not a valid email' do
      let(:subscribers) { [email: 'not@valid@example.com', name: 'FirstName LastName'] }

      it 'does not call adapter' do
        expect(adapter).not_to receive(:batch_subscribe)
        batch_subscribe
      end
    end

    context 'when exception is raised' do
      let(:options) do
        {
          extra: {
            identity_id: identity.id,
            contact_list_id: contact_list.id,
            arguments: [subscribers],
            remote_list_id: list_id,
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end
      before { allow(Rails.env).to receive(:test?).and_return(false) }

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:batch_subscribe).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect { batch_subscribe }.not_to raise_error
      end
    end
  end
end
