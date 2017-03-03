require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the Admin::UsersHelper. For example:
#
# describe Admin::UsersHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe Admin::UsersHelper do
  fixtures :bills, :sites, :subscriptions

  describe '#bills_for' do
    let(:site) { sites(:zombo) }

    it 'returns hash with bills to display' do
      expected_hash = site.bills.inject({}) { |r,e| r[e] = []; r }
      expect(helper.bills_for(site)).to include(expected_hash)
    end
  end

  describe '#bill_duration' do
    it "returns the bill's date in the correct format" do
      bill = bills(:paid_bill)
      bill.start_date = '2015-07-01'
      bill.end_date = '2015-07-31'

      duration = helper.bill_duration(bill)

      expect(duration).to eq('7/1/15-7/31/15')
    end
  end
end
