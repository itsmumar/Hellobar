describe CouponUse do
  it { is_expected.to validate_presence_of :bill }
  it { is_expected.to validate_presence_of :coupon }
end
