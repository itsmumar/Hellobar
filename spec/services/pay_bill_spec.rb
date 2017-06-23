describe PayBill do
  let(:payment_method) { create :payment_method }
  let(:subscription) { create :subscription, :pro, payment_method: payment_method }
  let(:bill) { create :bill, grace_period_allowed: false, subscription: subscription }
  let(:service) { PayBill.new(bill) }

  before { stub_cyber_source(:purchase) }

  describe '#call' do
    specify { expect { service.call }.to make_gateway_call(:purchase).with(bill.amount * 100, any_args) }
    specify { expect { service.call }.to change(bill, :status).to :paid }
    specify { expect { service.call }.to change { BillingAttempt.success.count }.to 1 }
    specify { expect { service.call }.to change { Bill.where(start_date: bill.end_date).pending.count }.to 1 }

    it 'returns given bill' do
      expect(service.call).to eql bill
    end

    it 'stores authorization_code in bill' do
      expect { service.call }.to make_gateway_call(:purchase).and_succeed.with_response(authorization: 'code')
      expect(bill.authorization_code).to eql 'code'
    end

    context 'when cybersource failed' do
      before { stub_cyber_source(:purchase, success: false) }

      it 'creates failed BillingAttempt' do
        expect { service.call }.to change(BillingAttempt.failed, :count).by 1
      end

      it 'sends event to Raven' do
        extra = {
          message: 'gateway error',
          bill: bill.id,
          amount: bill.amount
        }
        expect(Raven).to receive(:capture_message).with('Unsuccessful charge', extra: extra)
        service.call
      end
    end

    shared_examples 'doing nothing' do
      it 'does not change bill' do
        expect { service.call }.not_to make_gateway_call(:purchase).with(bill.amount * 100, any_args)
        expect { service.call }.not_to change(bill, :status)
        expect(BillingAttempt.success.count).to eql 0
      end
    end

    context 'when bill.status is :void' do
      let(:bill) { create :bill, status: :voided, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when bill.status is :paid' do
      let(:bill) { create :bill, status: :paid, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when bill.due_at in the future' do
      let(:bill) { create :bill, bill_at: 1.day.from_now, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when grace period allowed and bill_at + grace period >= today' do
      let(:bill) { create :bill, bill_at: Time.current, grace_period_allowed: true, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when final amount is 0' do
      before { allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(bill.amount) }

      specify { expect { service.call }.to change(bill, :status).to :paid }
      specify { expect { service.call }.not_to make_gateway_call(:purchase).with(bill.amount * 100, any_args) }
      specify { expect { service.call }.not_to change { BillingAttempt.success.count } }
    end

    context 'without payment_method' do
      before { bill.payment_method = nil }

      it 'changes subscription and capabilities' do
        expect { service.call }.to raise_error PayBill::Error, 'could not pay bill without credit card'
      end
    end
  end
end
