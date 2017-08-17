describe Admin::UsersHelper do
  describe '#bills_for' do
    let(:site) { create(:site) }
    let!(:bills) do
      [
        create(:pro_bill, :paid, site: site),
        create(:bill, site: site)
      ]
    end

    it 'returns hash with bills to display' do
      expect(helper.bills_for(site)).to match_array bills
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

  describe '#context_for_trial(user, bill)' do
    let(:bill) { create :pro_bill, :paid }
    let(:user) { create :user }

    it 'should be nil if the subscription is not on trial' do
      expect(helper.context_for_trial(user, bill)).to eq(nil)
    end

    context 'when subscription is free' do
      before do
        bill.update_attribute(:amount, 0)
        bill.subscription.credit_card = nil
      end

      it 'displays the correct text for v1.0 users on free trial' do
        user.update_attributes(wordpress_user_id: 123)
        expect(helper.context_for_trial(user, bill)).to eq('via 1.0 trial')
      end

      it 'displays the correct text for referrerd users on free trial' do
        allow(user).to receive(:was_referred?).and_return(true)
        expect(helper.context_for_trial(user, bill)).to eq('via referral')
      end

      it 'displays the correct text for admin-assigned free trials' do
        expect(helper.context_for_trial(user, bill)).to eq('via admin')
      end
    end
  end
end
