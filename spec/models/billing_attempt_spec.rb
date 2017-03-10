require 'spec_helper'

describe BillingAttempt do
  it 'should be read-only' do
    b = BillingAttempt.create
    b.response = 'different'
    expect { b.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { b.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  context '#refund!' do
    fixtures :all
    set_fixture_class payment_method_details: PaymentMethodDetails # pluralized class screws up naming convention

    before do
      PaymentMethodDetails.any_instance.stub(:charge).and_return([:success, 'response'])
    end

    it 'should create a refund' do
      payment_method_details(:always_successful_details)
      ba = billing_attempts(:success)
      refund_bill, refund_attempt = ba.refund!
      refund_bill.amount.should == ba.bill.amount * -1
      refund_bill.paid?.should be_true
    end

    it 'should not try to refund more than paid' do
      payment_method_details(:always_successful_details)
      ba = billing_attempts(:success)
      expect { ba.refund!(nil, (ba.bill.amount * -1) - 1) }.to raise_error(BillingAttempt::InvalidRefund)
    end
  end
end
