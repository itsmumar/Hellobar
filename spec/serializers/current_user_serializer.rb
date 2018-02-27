describe CurrentUserSerializer do
  let(:user) { create(:user, :with_site) }
  let(:serializer) { CurrentUserSerializer.new(user) }

  describe(:serializable_hash) do
    subject(:json) { serializer.serializable_hash }

    it 'includes first name' do
      expect(json[:first_name]).to eq(user.first_name)
    end

    it 'includes last name' do
      expect(json[:last_name]).to eq(user.last_name)
    end

    it 'includes email' do
      expect(json[:email]).to eq(user.email)
    end

    it 'includes sites' do
      expect(json[:sites]).to be_an(Array)
    end

    it 'includes site contact lists' do
      expect(json[:sites].first[:contact_lists]).to be_an(Array)
    end
  end
end
