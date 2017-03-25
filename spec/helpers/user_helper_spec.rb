RSpec.describe UserHelper do
  describe '#context_for_trial(user, bill)' do
    let(:bill) { create(:pro_bill, :paid) }

    it 'should be nil if the subscription is not on trial' do
      user = bill.subscription.user
      expect(helper.context_for_trial(user, bill)).to eq(nil)
    end

    it 'should display the correct text for v1.0 users on free trial' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      bill.subscription.user.update_attributes(wordpress_user_id: 123)
      user = bill.subscription.user
      expect(helper.context_for_trial(user, bill)).to eq('via 1.0 trial')
    end

    it 'should display the correct text for referrerd users on free trial' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      allow(bill.subscription.user).to receive(:was_referred?).and_return(true)
      user = bill.subscription.user
      expect(helper.context_for_trial(user, bill)).to eq('via referral')
    end

    it 'should display the correct text for admin-assigned free trials' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      user = bill.subscription.user
      expect(helper.context_for_trial(user, bill)).to eq('via admin')
    end
  end
end
