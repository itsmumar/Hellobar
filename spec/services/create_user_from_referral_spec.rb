describe CreateUserFromReferral do
  subject { CreateUserFromReferral.new(token) }

  let(:user) { instance_double(User) }
  let(:create_user_service) { instance_double(CreateTemporaryUser, call: user) }

  before do
    allow(CreateTemporaryUser).to receive(:new).and_return(create_user_service)
  end

  context 'when personal token given' do
    let(:referral) { create(:referral) }
    let(:token) { referral.referral_token.token }

    it 'finds or creates user by referral email' do
      expect(CreateTemporaryUser).to receive(:new).with(referral.email)
      expect(create_user_service).to receive(:call)

      subject.call
    end

    it 'returns user' do
      expect(subject.call).to eq(user)
    end
  end

  context 'when generic token given' do
    let(:sender) { create(:user) }
    let(:token) { sender.referral_token.token }

    it 'does not try to find or create a user' do
      expect(User).not_to receive(:find_or_create_temporary_user)

      subject.call
    end

    it 'returns nil' do
      expect(subject.call).to be_nil
    end
  end

  context 'when invalid token given' do
    let(:token) { 'abc' }

    it 'raises error' do
      expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when personal token has been already used' do
    let(:referral) { create(:referral, :signed_up) }
    let(:token) { referral.referral_token.token }

    it 'raises error' do
      expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
