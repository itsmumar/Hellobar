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

    context 'without identity' do
      let(:identity) { nil }
      let(:contact_list) { nil }

      it 'uses Hello Bar adapter' do
        expect(provider.adapter).to be_a ServiceProvider::Adapters::Hellobar
      end
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

    context 'with an invalid email' do
      let(:subscribe) { provider.subscribe(email: 'not@valid@example.com', name: 'FirstName LastName') }

      it 'does not call adapter' do
        expect(adapter).not_to receive(:subscribe)
        subscribe
      end
    end
  end
end
