describe RefundBill do
  subject!(:service) { RefundBill.new(bill) }

  let(:amount) { bill.amount }
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:subscription) { create :subscription, :pro, site: site, credit_card: credit_card }
  let(:bill) { create :bill, :pro, subscription: subscription }
  let(:latest_billing_attempt) { BillingAttempt.last }

  before { stub_cyber_source :purchase, :refund }
  before { PayBill.new(bill).call }

  it 'switches status of given bill to refunded', :freeze do
    service.call
    expect(bill).to be_refunded
  end

  it 'creates a new BillingAttempt record' do
    expect { service.call }.to change(BillingAttempt.refund.successful, :count).by(1)
  end

  it 'calls gateway.refund' do
    expect { service.call }
      .to make_gateway_call(:refund)
      .with(amount, bill.authorization_code)
  end

  it 'stores authorization_code in billing_attempt' do
    expect { service.call }.to make_gateway_call(:refund).and_succeed.with_response(authorization: 'code')
    expect(latest_billing_attempt.response).to eql 'code'
  end

  it 'cancels current subscription' do
    expect { service.call }.to change(bill.subscription.bills.pending, :count).to 0
    expect(bill.site.current_subscription).to be_a Subscription::Free
  end

  it 'calls TrackAffiliateRefund service' do
    expect(TrackAffiliateRefund).to receive_service_call.with(bill)
    service.call
  end

  context 'when cybersource failed' do
    before { stub_cyber_source(:refund, success?: false) }

    it 'sends event to Raven and raises error' do
      extra = {
        message: 'gateway error',
        bill: bill.id,
        amount: -bill.amount
      }

      expect(Raven).to receive(:capture_message).with('Unsuccessful refund', extra: extra)

      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Invalid response from payment gateway'
    end
  end

  context 'with pending bill' do
    before { allow(bill).to receive(:paid?).and_return(false) }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Cannot refund an unpaid bill'
    end
  end

  context 'when refund amount is 0' do
    let(:bill) { create :bill, :pro, subscription: subscription, amount: 0 }

    it 'raises InvalidRefund' do
      expect { service.call }.to raise_error RefundBill::InvalidRefund, 'Refund amount cannot be 0'
    end
  end
end
