require 'spec_helper'

describe Admin::PaymentMethodDetailsController do
  let!(:admin) { create(:admin) }
  let!(:user) { create(:user, :with_payment_method) }
  before(:each) { stub_current_admin(admin) }

  context 'PUT remove_cc_info' do
    before do
      cscc = CyberSourceCreditCard.new data: { 'token' => 'my_cool_token' }
      cscc.save(validate: false)
      CyberSourceCreditCard.stub(:find).and_return(cscc)
    end

    it 'removes the payment method' do
      expect {
        put :remove_cc_info, payment_method_detail_id: user.payment_methods.first.id, user_id: user.id
      }.to change(user.payment_methods, :count).by(-1)
    end

    it 'removes the cscc token' do
      put :remove_cc_info, payment_method_detail_id: user.payment_methods.first.id, user_id: user.id
      expect(CyberSourceCreditCard.last.reload.token).to be_nil
    end
  end
end
