require 'spec_helper'

describe Referrals::RedeemForSender do
  fixtures :all
  before :each do
    @user = users(:joey)
    @referral = create(:referral, state: 'installed', available: true, sender: @user)
  end

  it 'should redeem and make the referral unavailable' do
    Referrals::RedeemForSender.run(site: sites(:zombo))
    @referral.reload

    expect(@referral.available).to be_false
    expect(@referral.redeemed_by_sender_at).to be_within(2.seconds).of(Time.now)
  end
end