describe Referrals::HandleToken do
  it 'does nothing if no token is passed in' do
    expect_any_instance_of(Referral).not_to receive(:save)
    Referrals::HandleToken.run(user: build(:user), token: nil)
  end

  it 'does nothing if a user with more than one site is passed in' do
    user = create(:user, :with_sites, count: 2)
    referral = create(:referral, state: :sent)

    expect(user.sites.count > 1).to be_truthy
    expect_any_instance_of(Referral).not_to receive(:save)

    Referrals::HandleToken.run(user: user, token: referral.referral_token.token)
  end

  it 'creates a new referral if a user token is passed in' do
    sender = create(:user)
    recipient = create(:user)

    expect {
      Referrals::HandleToken.run(user: recipient, token: sender.referral_token.token)
    }.to change { Referral.count }.by(1)
  end

  it 'updates an existing referral if its token is passed in' do
    referral = create(:referral, state: :sent)

    Referrals::HandleToken.run(user: build(:user), token: referral.referral_token.token)
    expect(referral.reload.signed_up?).to be_truthy
  end
end
