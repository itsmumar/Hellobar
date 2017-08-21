describe Coupon do
  describe '.for_referrals' do
    it 'returns the coupon for referrals' do
      coupon = create :coupon, :referral

      expect(Coupon.for_referrals).to eq coupon
    end
  end
end
