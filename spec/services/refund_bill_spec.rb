describe RefundBill do
  let(:amount) { bill.amount }
  let(:bill) { create :pro_bill }
  let!(:service) { described_class.new(bill, amount) }
  let(:latest_refund) { Bill::Refund.last }

  it 'returns array of Bill::Refund and BillingAttempt' do
    expect(service.call).to match_array [instance_of(Bill::Refund), instance_of(BillingAttempt)]
  end

  it 'creates Bill::Refund', :freeze do
    expect { service.call }.to change(Bill::Refund, :count).by(1)

    expect(latest_refund.subscription).to eql bill.subscription
    expect(latest_refund.amount).to eql(-bill.amount)
    expect(latest_refund.description).to eql 'Refund due to customer service request'
    expect(latest_refund.bill_at).to eql Time.current
    expect(latest_refund.start_date).to eql Time.current
    expect(latest_refund.end_date).to eql bill.end_date
    expect(latest_refund.refunded_billing_attempt).to eql bill.successful_billing_attempt
    expect(latest_refund.discount).to be 0
    expect(latest_refund.base_amount).to eql(-bill.amount.to_i)
    expect(latest_refund.status).to eql :paid
  end

  it 'creates BillingAttempt' do
    expect { service.call }.to change(BillingAttempt, :count).by(1)
  end

  context 'without successful billing attempt' do
    let(:bill) { create :past_due_bill }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Cannot refund unsuccessful billing attempt'
    end
  end

  context 'when refund amount is more than paid amount' do
    let(:amount) { 100 }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Cannot refund more than paid amount'
    end
  end

  context 'when refund amount is 0' do
    let(:amount) { 0 }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Refund amount cannot be 0'
    end
  end

  context 'when payment method is missing' do
    before { allow(bill.subscription).to receive(:payment_method).and_return(nil) }

    it 'raises MissingPaymentMethod' do
      expect { service.call }.to raise_error RefundBill::MissingPaymentMethod, 'Could not find payment method'
    end
  end
end
