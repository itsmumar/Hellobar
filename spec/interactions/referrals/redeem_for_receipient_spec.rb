require 'spec_helper'

describe Referrals::RedeemForRecipient do
  fixtures :users
  before :each do
    create(:referral_coupon)
    @user = users(:joey)
    @site = create(:site)
    @site.change_subscription(build(:free_subscription, user: @user))
  end

  it "subscribes to Pro with a 0.00 bill when referred and installed" do
    referral = create(:referral, recipient: users(:joey), state: 'installed')
    Referrals::RedeemForRecipient.run(site: @site)
    bill = @site.current_subscription.active_bills.last

    referral.reload
    expect(referral.redeemed_by_recipient_at).not_to be_nil
    expect(referral.available_to_sender).to be_true
    expect(@site.current_subscription).to be_a(Subscription::Pro)
    expect(bill.amount).to eq(0.0)
    expect(bill.discount).to eq(Coupon::REFERRAL_AMOUNT)
  end

  it "raises an exception when referred and merely signed_up" do
    create(:referral, recipient: users(:joey), state: 'signed_up')

    expect(lambda do
      Referrals::RedeemForRecipient.run(site: @site)
    end).to raise_error(Referrals::NotInstalled)
  end

  it "raises nothing when no referral exists" do
    expect(lambda do
      Referrals::RedeemForRecipient.run(site: @site)
    end).not_to raise_error
    expect(@site.current_subscription).to be_a(Subscription::Free)
  end
end