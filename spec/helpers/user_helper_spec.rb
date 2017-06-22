RSpec.describe UserHelper do
  describe '#context_for_trial(user, bill)' do
    let(:bill) { create :pro_bill, :paid }
    let(:user) { create :user }

    it 'should be nil if the subscription is not on trial' do
      expect(helper.context_for_trial(user, bill)).to eq(nil)
    end

    it 'should display the correct text for v1.0 users on free trial' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      user.update_attributes(wordpress_user_id: 123)
      expect(helper.context_for_trial(user, bill)).to eq('via 1.0 trial')
    end

    it 'should display the correct text for referrerd users on free trial' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      allow(user).to receive(:was_referred?).and_return(true)
      expect(helper.context_for_trial(user, bill)).to eq('via referral')
    end

    it 'should display the correct text for admin-assigned free trials' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      expect(helper.context_for_trial(user, bill)).to eq('via admin')
    end
  end
end
