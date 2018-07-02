describe ServiceProvider::Adapters::Base do
  let(:client) { double('client') }
  let(:adapter) { described_class.new(client) }

  describe '#lists' do
    it 'returns empty array' do
      expect(adapter.lists).to eql []
    end
  end

  describe '#tags' do
    it 'returns nil' do
      expect(adapter.tags).to be_nil
    end
  end

  describe '#connected?' do
    specify { expect(adapter).to be_connected }
  end
end
