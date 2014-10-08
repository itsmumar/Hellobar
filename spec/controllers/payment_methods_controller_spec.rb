require 'spec_helper'

describe PaymentMethodsController, '#update' do
  fixtures :all

  before do
    stub_current_user users(:joey)
    request.env["HTTP_ACCEPT"] = 'application/json'
  end

  let(:site) { sites(:zombo) }

  context 'updating a payment detail' do
    it 'changes the subscription with the correct payment method and detail' do
      payment_method = payment_methods(:always_successful)
      data = PaymentForm.new({}).to_hash

      CyberSourceCreditCard.should_receive(:new).
                            with(payment_method: payment_method, data: data).
                            and_return(PaymentMethodDetails.new)

      put :update, id: payment_method.id, payment_method_details: {}, billing: { plan: 'pro', cycle: 'monthly' }, site_id: site.id
    end
  end

  context 'linking an existing payment detail' do
    it 'does not create a new payment method'
    it 'does not create a new payment method detail'
    it 'changes the subscription with the correct payment method and detail'
  end
end
