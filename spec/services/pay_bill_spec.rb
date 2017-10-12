describe PayBill do
  let(:credit_card) { create :credit_card }
  let(:subscription) { create :subscription, :pro, credit_card: credit_card }
  let(:bill) { create :bill, grace_period_allowed: false, subscription: subscription }
  let(:service) { PayBill.new(bill) }

  before { stub_cyber_source(:purchase) }

  describe '#call' do
    specify { expect { service.call }.to make_gateway_call(:purchase).with(bill.amount, any_args) }
    specify { expect { service.call }.to change(bill, :status).to Bill::PAID }
    specify { expect { service.call }.to change { BillingAttempt.successful.count }.to 1 }
    specify { expect { service.call }.to change { BillingAttempt.successful.count }.to 1 }

    it 'creates pending bill for next period', :freeze do
      expect { service.call }.to change { subscription.bills.pending.last }.from(nil)
      expect(subscription.bills.pending.last.bill_at).to eql 3.days.until(bill.end_date)
    end

    it 'returns given bill' do
      expect(service.call).to eql bill
    end

    it 'regenerates script' do
      expect { service.call }
        .to have_enqueued_job(GenerateStaticScriptJob).with(bill.site)
    end

    it 'stores authorization_code in bill' do
      expect { service.call }.to make_gateway_call(:purchase).and_succeed.with_response(authorization: 'code')
      expect(bill.authorization_code).to eql 'code'
    end

    context 'when site had problems with payment' do
      let!(:failed_bill) { create :bill, :problem, site: bill.site }

      it 'voids problem bills' do
        expect { service.call }
          .to change { failed_bill.reload.status }
          .from(Bill::FAILED)
          .to(Bill::VOIDED)

        expect(bill.site.reload.bills_with_payment_issues).to be_empty
      end
    end

    context 'when cybersource failed' do
      before { stub_cyber_source(:purchase, success?: false) }

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
        expect { service.call }.not_to change(BillingAttempt.successful, :count)
      end
    end

    context 'when bill.status is :void' do
      let(:bill) { create :bill, :void, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when bill.status is :paid' do
      let(:bill) { create :bill, :paid, subscription: subscription }

      it_behaves_like 'doing nothing'
    end

    context 'when final amount is 0' do
      before do
        allow_any_instance_of(DiscountCalculator)
          .to receive(:current_discount).and_return(bill.amount)
      end

      specify { expect { service.call }.to change(bill, :status).to Bill::PAID }
      specify { expect { service.call }.not_to make_gateway_call(:purchase) }
      specify { expect { service.call }.not_to change { BillingAttempt.successful.count } }
    end

    context 'without credit card' do
      before { bill.credit_card = nil }

      it 'changes subscription and capabilities' do
        expect { service.call }.to raise_error PayBill::Error, 'could not pay bill without credit card'
      end
    end
  end
end
