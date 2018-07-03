describe AffiliateCommission do
  let(:bill) { build :bill }

  it { is_expected.to validate_presence_of :identifier }
  it { is_expected.to validate_presence_of :bill }

  it 'belongs to bill' do
    expect(bill.build_affiliate_commission).to be_a AffiliateCommission
  end
end
