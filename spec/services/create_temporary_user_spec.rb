describe CreateTemporaryUser do
  let(:email) { 'donald.duck@disney.com' }

  describe '#call' do
    subject { CreateTemporaryUser.new(email).call }

    it 'creates a new user' do
      expect { subject }.to change { User.count }.by(1)
    end

    it 'returns a user' do
      expect(subject).to be_a(User)
    end

    it 'uses given email' do
      expect(subject.email).to eq(email)
    end

    it 'sets TEMPORARY status' do
      expect(subject.status).to eq(User::TEMPORARY)
    end

    it 'sets random password' do
      expect(subject.password).to be_present
    end

    context 'when temporary user already exists' do
      let!(:existing_user) { User.find_or_create_temporary_user(email) }

      it 'does not create a new user' do
        expect { subject }.not_to change { User.count }
      end

      it 'returns an existing user' do
        expect(subject).to eq(existing_user)
      end
    end
  end
end
