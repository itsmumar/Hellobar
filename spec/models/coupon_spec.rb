require 'spec_helper'

describe Coupon do
  it 'has a way to fetch the coupon for referrals' do
    c = Coupon.create(public: false, amount: 10.0, label: Coupon::REFERRAL_LABEL)
    expect(Coupon.for_referrals).to eq(c)
  end
end
