describe Coupon do
  it { is_expected.to validate_presence_of :label }
  it { is_expected.to validate_presence_of :amount }
  it { is_expected.to validate_numericality_of(:amount).is_greater_than 0 }

  describe '.for_referrals' do
    it 'returns the coupon for referrals' do
      coupon = create :coupon, :referral

      expect(Coupon.for_referrals).to eq coupon
    end
  end

  describe '.promotional' do
    it 'returns coupon for promotional' do
      coupon = create :coupon, :promotional

      expect(Coupon.promotional).to eq coupon
    end
  end
end
