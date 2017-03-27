RSpec.describe Admin::UsersHelper do
  describe '#bills_for' do
    let(:site) { create(:site) }

    it 'returns hash with bills to display' do
      expected_hash = site.bills.inject({}) { |r, e| r.update e => [] }
      expect(helper.bills_for(site)).to include(expected_hash)
    end
  end

  describe '#bill_duration' do
    it "returns the bill's date in the correct format" do
      bill = create(:pro_bill, :paid)
      bill.start_date = '2015-07-01'
      bill.end_date = '2015-07-31'

      duration = helper.bill_duration(bill)

      expect(duration).to eq('7/1/15-7/31/15')
    end
  end
end
