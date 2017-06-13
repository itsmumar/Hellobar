describe ObfuscatedID do
  describe '.generate' do
    it 'generates pseudo-random string' do
      expect(ObfuscatedID.generate(123_456)).to be_a String
      expect(ObfuscatedID.generate(123_456)).not_to eql ObfuscatedID.generate(123_456)
    end

    it 'uses _ for zero' do
      expect(ObfuscatedID.generate(0)).to eql '_'
    end
  end

  describe '.parse' do
    let(:obfuscated) { [ObfuscatedID.generate(123_456), ObfuscatedID.generate(100_000)] }

    it 'parses obfuscated id into original number' do
      expect(ObfuscatedID.parse(obfuscated.first)).to eql 123_456
      expect(ObfuscatedID.parse(obfuscated.last)).to eql 100_000
    end
  end
end
