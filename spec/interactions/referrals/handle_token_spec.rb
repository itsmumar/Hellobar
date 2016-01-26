require 'spec_helper'

describe Referrals::HandleToken do
  fixtures :all

  it "does nothing if no token is passed in" do
    expect_any_instance_of(Referral).not_to receive(:save)
    Referrals::HandleToken.run(user: build(:user), token: nil)
  end

  it "does nothing if a user with more than one site is passed in" do
    user = users(:joey)
    referral = create(:referral, state: :sent)

    expect(user.sites.count > 1).to be_true
    expect_any_instance_of(Referral).not_to receive(:save)

    Referrals::HandleToken.run(user: user, token: referral.referral_token.token)
  end

  it "creates a new referral if a user token is passed in" do
    sender = users(:joey)
    recipient = create(:user)

    expect do
      Referrals::HandleToken.run(user: recipient, token: sender.referral_token.token)
    end.to change { Referral.count }.by(1)
  end

  it "updates an existing referral if its token is passed in" do
    referral = create(:referral, state: :sent)

    Referrals::HandleToken.run(user: build(:user), token: referral.referral_token.token)
    expect(referral.reload.signed_up?).to be_true
  end
end