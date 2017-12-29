describe CreateUserFromReferral do
  subject { CreateUserFromReferral.new(token) }

  let(:user) { instance_double(User) }

  before do
    allow(User).to receive(:find_or_create_temporary_user).and_return(user)
  end

  context 'when personal token given' do
    let(:referral) { create(:referral) }
    let(:token) { referral.referral_token.token }

    it 'finds or creates user by referral email' do
      expect(User).to receive(:find_or_create_temporary_user).with(referral.email)

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

    it 'returns falsey' do
      expect(subject.call).to be_falsey
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
