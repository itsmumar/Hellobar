require 'spec_helper'

describe Referrals::RedeemForSender do
  fixtures :all
  it 'should raise an error if there are no referrals available' do
    expect(lambda do
      Referrals::RedeemForSender.run(site: sites(:past_due_site))
    end).to raise_error(Referrals::NoAvailableReferrals)
  end

  describe 'redeeming a referral for a site with billing problems' do
    before :each do
      ownership = create(:site_ownership, site: sites(:past_due_site))
      @user = ownership.user
      @site = ownership.site
      @referral = create(:referral, state: :installed, available_to_sender: true, sender: @user, site: @site)
      Referrals::RedeemForSender.run(site: @site)
      @referral.reload
    end

    it 'should redeem and make the referral unavailable' do
      expect(@referral.available_to_sender).to be_false
      expect(@referral.redeemed_by_sender_at).to be_within(2.seconds).of(Time.now)
    end

    it 'should mark the latest unpaid bill as paid' do
      subscription = @site.current_subscription
      expect(subscription.problem_with_payment?).to be_false
    end

    it 'should mark the last bill as paid with an amount of 0.0 and discounted' do
      bill = bills(:past_due_bill)
      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq([bill.base_amount, Coupon::REFERRAL_AMOUNT].min)
    end
  end

  describe 'redeeming a referral for a free site' do
    before :each do
      @site = sites(:free_site)
      @user = users(:joey)
      @referral = create(:referral, state: :installed, available_to_sender: true, sender: @user, site: @site)
      Referrals::RedeemForSender.run(site: sites(:free_site))
      @referral.reload
      @subscription = @site.current_subscription
      @bill = @subscription.active_bills.last
    end

    it 'should redeem and make the referral unavailable' do
      expect(@referral.available_to_sender).to be_false
      expect(@referral.redeemed_by_sender_at).to be_within(2.seconds).of(Time.now)
    end

    it 'sets the site to a Pro subscription' do
      expect(@subscription).to be_a(Subscription::Pro)
    end

    it 'should mark the last bill as paid with an amount of 0.0 and discounted' do
      expect(@bill.amount).to eq(0.0)
      expect(@bill.discount).to eq(Coupon::REFERRAL_AMOUNT)
    end
  end
end
