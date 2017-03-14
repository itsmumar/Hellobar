require 'spec_helper'

describe BillingAttempt do
  it 'should be read-only' do
    b = BillingAttempt.create
    b.response = 'different'
    expect { b.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { b.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  context '#refund!' do
    set_fixture_class payment_method_details: PaymentMethodDetails # pluralized class screws up naming convention

    before do
      PaymentMethodDetails.any_instance.stub(:charge).and_return([:success, 'response'])
    end

    let(:paid_bill) { create(:pro_bill, :paid) }

    it 'should create a refund' do
      billing_attempt = paid_bill.billing_attempts.last
      refund_bill, refund_attempt = billing_attempt.refund!
      refund_bill.amount.should == billing_attempt.bill.amount * -1
      refund_bill.paid?.should be_true
    end

    it 'should not try to refund more than paid' do
      billing_attempt = create(:billing_attempt, :success, bill: paid_bill)
      expect {
        billing_attempt.refund!(nil, (billing_attempt.bill.amount * -1) - 1)
      }.to raise_error(BillingAttempt::InvalidRefund)
    end
  end
end
