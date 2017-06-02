describe ServiceProviders::Provider do
  let(:adapter_class) { Class.new(ServiceProviders::Adapters::Base) }
  let(:adapter) { adapter_class.new(double('client')) }
  let(:identity) { create :identity, provider: 'foo' }
  let(:contact_list) { create :contact_list, :with_tags, identity: identity }
  let(:provider) { described_class.new(contact_list) }

  # TODO: temporary solution, should be removed after Identity refactoring
  before { allow(Settings).to receive(:identity_providers).and_return(foo: {}) }
  before { allow(adapter_class).to receive(:new).and_return(adapter) }
  before { adapter_class.register 'foo' }

  describe '.configure' do
    before do
      described_class.configure do |config|
        config.foo.api_key = 1
      end
    end

    it 'yields config' do
      expect(described_class.config.foo.api_key).to eq 1
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
            contact_list_id: contact_list.id,
            arguments: [],
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:lists).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect {
          provider.lists
        }.to raise_error(StandardError)
      end
    end
  end

  describe '#subscribe' do
    let(:list_id) { 1 }
    let(:params) { { email: 'email@example.com', name: 'FirstName LastName', tags: [], double_optin: false } }
    let(:contact_list) { create(:contact_list, double_optin: false, identity: identity) }
    let(:provider) { described_class.new(contact_list) }

    it 'calls adapter' do
      expect(adapter).to receive(:subscribe).with(list_id, params)
      provider.subscribe(list_id, email: 'email@example.com', name: 'FirstName LastName')
    end

    context 'when contact_list.tags is not empty' do
      let(:contact_list) { create(:contact_list, :with_tags, identity: identity) }
      let(:provider) { described_class.new(contact_list) }
      let(:params) { { email: 'email@example.com', name: 'FirstName LastName', tags: ['id1', 'id2'], double_optin: true } }

      it 'passes tags to adapter' do
        expect(adapter).to receive(:subscribe).with(list_id, params)
        provider.subscribe(list_id, email: 'email@example.com', name: 'FirstName LastName')
      end
    end

    context 'when exception is raised' do
      let(:options) do
        {
          extra: {
            contact_list_id: contact_list.id,
            arguments: [list_id, email: 'email@example.com', name: 'FirstName LastName'],
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:subscribe).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect {
          provider.subscribe(list_id, email: 'email@example.com', name: 'FirstName LastName')
        }.to raise_error(StandardError)
      end
    end
  end

  describe '#batch_subscribe' do
    let(:list_id) { 1 }
    let(:subscribers) { [email: 'email@example.com', name: 'FirstName LastName'] }
    let(:contact_list) { create(:contact_list, double_optin: false, identity: identity) }
    let(:provider) { described_class.new(contact_list) }

    it 'calls adapter' do
      expect(adapter).to receive(:batch_subscribe).with(list_id, subscribers, double_optin: false)
      provider.batch_subscribe(list_id, subscribers)
    end

    context 'when exception is raised' do
      let(:options) do
        {
          extra: {
            contact_list_id: contact_list.id,
            arguments: [list_id, subscribers],
            double_optin: contact_list.double_optin,
            tags: contact_list.tags
          },
          tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
        }
      end

      it 'calls Raven.capture_exception' do
        expect(adapter).to receive(:batch_subscribe).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
        expect {
          provider.batch_subscribe(list_id, subscribers)
        }.to raise_error(StandardError)
      end
    end
  end
end
