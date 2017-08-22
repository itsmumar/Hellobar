describe RefundBill do
  let(:amount) { bill.amount }
  let(:credit_card) { create :credit_card }
  let(:subscription) { create :subscription, :pro, credit_card: credit_card }
  let(:bill) { create :pro_bill, subscription: subscription }
  let!(:service) { described_class.new(bill, amount: amount) }
  let(:latest_refund) { Bill::Refund.last }
  let(:latest_billing_attempt) { BillingAttempt.last }

  before { stub_cyber_source :purchase, :refund }
  before { PayBill.new(bill).call }

  it 'returns a Bill::Refund' do
    expect(service.call).to be_a Bill::Refund
  end

  it 'creates a new Bill::Refund', :freeze do
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

  it 'calls gateway.refund' do
    expect { service.call }
      .to make_gateway_call(:refund)
      .with(amount, bill.authorization_code)
  end

  it 'stores authorization_code in bill' do
    expect { service.call }.to make_gateway_call(:refund).and_succeed.with_response(authorization: 'code')
    expect(latest_refund.authorization_code).to eql 'code'
  end

  it 'allows partialy refunds' do
    RefundBill.new(bill, amount: 1).call
    RefundBill.new(bill, amount: 1).call
    RefundBill.new(bill, amount: bill.amount - 2).call

    expect { RefundBill.new(bill, amount: 1).call }
      .to raise_error RefundBill::InvalidRefund, 'Cannot refund more than paid amount'
  end

  it 'cancels current subscription' do
    expect { service.call }.to change(bill.subscription.bills.pending, :count).to 0
    expect(bill.site.current_subscription).to be_a Subscription::Free
  end

  context 'when cybersource failed' do
    before { stub_cyber_source(:refund, success?: false) }

    it 'creates failed BillingAttempt' do
      expect { service.call }.to change(BillingAttempt.failed, :count).by 1
    end

    it 'sends event to Raven and return false' do
      extra = {
        message: 'gateway error',
        bill: bill.id,
        amount: -bill.amount
      }
      expect(Raven).to receive(:capture_message).with('Unsuccessful refund', extra: extra)
      expect(service.call).to be_a Bill::Refund
    end
  end

  context 'with pending bill' do
    before { allow(bill).to receive(:paid?).and_return(false) }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Cannot refund an unpaid bill'
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

  context 'when refund amount is less than bill amount' do
    let(:amount) { bill.amount / 2 }

    it 'refunds successfully' do
      service.call
      expect(latest_refund.amount).to eql(-amount)
    end
  end

  context 'when credit card is missing' do
    before { allow(bill).to receive(:paid_with_credit_card).and_return(nil) }

    it 'raises MissingCreditCard' do
      expect { service.call }
        .to raise_error RefundBill::MissingCreditCard, 'Could not find credit card'
    end
  end
end
