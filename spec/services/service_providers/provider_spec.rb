describe ServiceProviders::Provider do
  before { described_class.register 'foo', double('foo adapter', new: true) }

  let(:identity) { create :identity, provider: 'foo' }
  let(:provider) { described_class.new(identity) }

  describe '.initialize' do
    it '...' do
      expect { provider }.not_to raise_error
    end
  end
end
