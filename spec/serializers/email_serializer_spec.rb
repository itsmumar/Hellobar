describe EmailSerializer do
  let(:email) { create(:email) }
  let(:serializer) { EmailSerializer.new(email) }

  describe(:serializable_hash) do
    subject(:json) { serializer.serializable_hash }

    it 'includes id' do
      expect(json[:id]).to eq(email.id)
    end

    it 'includes from name' do
      expect(json[:from_name]).to eq(email.from_name)
    end

    it 'includes from email' do
      expect(json[:from_email]).to eq(email.from_email)
    end

    it 'includes subject' do
      expect(json[:subject]).to eq(email.subject)
    end

    it 'includes body' do
      expect(json[:body]).to eq(email.body)
    end

    it 'includes plain body' do
      expect(json[:plain_body]).to eq(email.plain_body)
    end
  end
end
