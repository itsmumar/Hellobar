require 'spec_helper'

describe BillsHelper do
  it 'yields a list of coupons and uses' do
    coupon = create(:referral_coupon)
    bill = create(:pro_bill)
    3.times { bill.coupon_uses.create(coupon: coupon) }
    run_coupon = ->(b) { helper.coupons_and_uses(bill, &b) }

    expect(run_coupon).to yield_with_args(coupon, 3)
    expect(run_coupon).to yield_control.once
  end

  it 'displays a nice coupon label' do
    coupon = build(:referral_coupon)
    label = helper.coupon_label(coupon, 3)

    expect(label).to include(coupon.label)
    expect(label).to include('&times; 3')
    expect(label).to include(helper.number_to_currency(Coupon::REFERRAL_AMOUNT))
  end

  it 'displays a discount' do
    coupon = build(:referral_coupon)
    label = helper.coupon_discount(coupon, 3)

    expect(label).to include(helper.number_to_currency(Coupon::REFERRAL_AMOUNT * -3))
  end
end
