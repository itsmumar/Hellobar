describe DynamoDB do
  describe '.clear_cache' do
    let(:key) { 'key' }

    it 'delete cache entity' do
      expect(Rails.cache).to receive(:delete).with("DynamoDB/#{ key }")
      DynamoDB.clear_cache(key)
    end
  end
end
