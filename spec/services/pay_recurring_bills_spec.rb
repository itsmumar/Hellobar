describe PayRecurringBills do
  describe '#call', freeze: 30.days.ago do
    let(:report) { BillingReport.new(1) }
    let(:service) { PayRecurringBills.new }

    before { allow(BillingReport).to receive(:new).and_return(report) }

    before do
      allow(report).to receive(:info)
    end

    shared_context 'pay bill' do
      specify do
        expect(PayBill).to receive_service_call.and_return(double(paid?: true))
        service.call
      end
    end

    shared_context 'do not pay bill' do
      specify do
        expect(PayBill).not_to receive_service_call
        service.call
      end
    end

    context 'subscription should not be inactive because of billing' do
      let(:payment_method) { create :payment_method }
      let(:site) { create :site, user: payment_method.user }

      before { stub_cyber_source :purchase }

      specify 'tries to charge users 3 days before the subscription ends', freeze: '2017-07-01 11:00 UTC' do
        ChangeSubscription.new(site, { subscription: 'pro' }, payment_method).call
        expect(site).to be_capable_of :pro

        travel_to '2017-07-28 13:00 UTC' do
          service.call
        end

        travel_to '2017-07-31 00:00 UTC' do
          expect(site).to be_capable_of :pro
        end

        travel_to '2017-08-01 11:00 UTC' do
          expect(site).to be_capable_of :pro
        end
      end
    end

    it 'logs results' do
      create :free_bill
      expect(report).to receive(:start)
      expect(report).to receive(:count).exactly(1).times
      expect(report).to receive(:finish)
      expect(report).to receive(:email)
      service.call
    end

    context 'with zero amount bill' do
      let!(:zero_amount_bill) { create :free_bill }

      specify do
        expect { service.call }
          .to change { zero_amount_bill.reload.status }.to(:paid)
      end

      include_examples 'pay bill'
    end

    context 'with bill which has no site anymore' do
      let!(:bill_without_site) { create :bill }
      before { bill_without_site.site.delete }

      specify do
        expect(report).to receive(:void).with(bill_without_site)

        expect { service.call }
          .to change { bill_without_site.reload.status }.to(:voided)
      end

      include_examples 'do not pay bill'
    end

    context 'with bill which has been attempted' do
      let!(:bill_with_attempt) { create :bill, :with_attempt }
      let(:last_billing_attempt) { bill_with_attempt.billing_attempts.last }

      specify do
        expect(report).to receive(:skip).with(bill_with_attempt, last_billing_attempt)

        expect { service.call }
          .not_to change { bill_with_attempt.reload.status }
      end

      include_examples 'do not pay bill'
    end

    context 'with bill which has no payment method' do
      let!(:bill_without_payment_method) { create :bill }

      before { bill_without_payment_method.payment_method.delete }

      specify do
        expect(report).to receive(:no_payment_method)

        expect { service.call }
          .not_to change { bill_without_payment_method.reload.status }
      end

      include_examples 'do not pay bill'
    end

    context 'with bill which has no payment details' do
      let!(:bill_without_payment_details) { create :bill }

      before { bill_without_payment_details.payment_method.details.delete_all }

      specify do
        expect(report).to receive(:no_details)

        expect { service.call }
          .not_to change { bill_without_payment_details.reload.status }
      end

      include_examples 'do not pay bill'
    end

    context 'with payable bill' do
      let!(:bill) { create :bill }

      before { stub_cyber_source :purchase }

      specify do
        expect(report).to receive(:success)

        expect { service.call }
          .to change { bill.reload.status }.to :paid
      end

      include_examples 'pay bill'

      context 'when bill had payment problem before' do
        let!(:bill) { create :bill, :problem }

        specify do
          expect { service.call }
            .to change { bill.reload.status }.to :paid
        end

        include_examples 'pay bill'
      end

      context 'when unsuccessful' do
        before { stub_cyber_source :purchase, success?: false }

        specify do
          expect(report).to receive(:fail)

          expect { service.call }
            .to change { bill.reload.status }.to :problem
        end
      end

      context 'when exception' do
        let(:exception) { RuntimeError.new('error') }
        before { expect(PayBill).to receive_service_call.and_raise exception }

        specify do
          expect(report).to receive(:exception).with(exception)

          expect { service.call }.to raise_error exception
        end
      end
    end
  end
end
