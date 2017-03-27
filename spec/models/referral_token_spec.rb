describe ReferralToken do
  it 'should be generated for a new user' do
    user = create(:user)

    expect(user.referral_token).not_to be_nil
    expect(user.referral_token.token).to be_a(String)
  end

  it 'should be generated for a new referral' do
    referral = create(:referral)

    expect(referral.referral_token).not_to be_nil
    expect(referral.referral_token.token).to be_a(String)
  end
end
