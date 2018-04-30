describe RefundBill do
  let(:amount) { bill.amount }
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:subscription) { create :subscription, :pro, site: site, credit_card: credit_card }
  let(:bill) { create :bill, :pro, subscription: subscription }
  let!(:refund_bill) { RefundBill.new(bill) }
  let(:latest_refund) { Bill::Refund.last }
  let(:latest_billing_attempt) { BillingAttempt.last }

  before { stub_cyber_source :purchase, :refund }
  before { PayBill.new(bill).call }

  it 'creates a new Bill::Refund', :freeze do
    expect { refund_bill.call }.to change(Bill::Refund, :count).by(1)

    expect(latest_refund.subscription).to eql bill.subscription
    expect(latest_refund.amount).to eql(-bill.amount)
    expect(latest_refund.description).to eql 'Refund due to customer service request'
    expect(latest_refund.bill_at).to eql Time.current
    expect(latest_refund.start_date).to eql Time.current
    expect(latest_refund.end_date).to eql bill.end_date
    expect(latest_refund.discount).to be 0
    expect(latest_refund.base_amount).to eql(-bill.amount.to_i)
    expect(latest_refund.status).to eql Bill::REFUNDED
  end

  it 'creates a new BillingAttempt record' do
    expect { refund_bill.call }.to change(BillingAttempt.refund.successful, :count).by(1)
  end

  it 'calls gateway.refund' do
    expect { refund_bill.call }
      .to make_gateway_call(:refund)
      .with(amount, bill.authorization_code)
  end

  it 'stores authorization_code in bill' do
    expect { refund_bill.call }.to make_gateway_call(:refund).and_succeed.with_response(authorization: 'code')
    expect(latest_refund.authorization_code).to eql 'code'
  end

  it 'cancels current subscription' do
    expect { refund_bill.call }.to change(bill.subscription.bills.pending, :count).to 0
    expect(bill.site.current_subscription).to be_a Subscription::Free
  end

  context 'when cybersource failed' do
    before { stub_cyber_source(:refund, success?: false) }

    it 'sends event to Raven and return false' do
      extra = {
        message: 'gateway error',
        bill: bill.id,
        amount: -bill.amount
      }
      expect(Raven).to receive(:capture_message).with('Unsuccessful refund', extra: extra)
      expect(refund_bill.call).to be_a Bill::Refund
    end
  end

  context 'with pending bill' do
    before { allow(bill).to receive(:paid?).and_return(false) }

    it 'raises InvalidRefund' do
      expect { refund_bill.call }.to raise_error RefundBill::InvalidRefund, 'Cannot refund an unpaid bill'
    end
  end

  context 'when refund amount is 0' do
    let(:bill) { create :bill, :pro, subscription: subscription, amount: 0 }

    it 'raises InvalidRefund' do
      expect { refund_bill.call }.to raise_error RefundBill::InvalidRefund, 'Refund amount cannot be 0'
    end
  end

  context 'when refund amount is less than bill amount' do
    let(:bill) { create :bill, :pro, subscription: subscription, amount: 10 }

    it 'refunds successfully' do
      refund_bill.call
      expect(latest_refund.amount).to eql(-amount)
    end
  end

  context 'when user has canceled his account' do
    before do
      allow_any_instance_of(StaticScript).to receive(:destroy)
      allow_any_instance_of(IntercomGateway).to receive(:delete_user)

      DestroyUser.new(user).call

      bill.reload
    end

    it 'creates a refund bill' do
      refund_bill.call

      expect(bill.refund).to be_a Bill::Refund
    end
  end
end
