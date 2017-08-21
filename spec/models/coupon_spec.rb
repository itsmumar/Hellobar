describe Coupon do
  describe '.for_referrals' do
    it 'returns the coupon for referrals' do
      coupon = Coupon.create(public: false, amount: Coupon::REFERRAL_AMOUNT, label: Coupon::REFERRAL_LABEL)

      expect(Coupon.for_referrals).to eq coupon
    end
  end
end
