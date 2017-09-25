describe PayRecurringBills do
  describe '#call', freeze: 30.days.ago do
    let(:report) { BillingReport.new(1) }
    let(:service) { PayRecurringBills.new }

    before { allow(BillingReport).to receive(:new).and_return(report) }

    before do
      allow(report).to receive(:info)
      allow(report).to receive(:email)
    end

    shared_examples 'pay bill' do
      specify do
        expect(PayBill).to receive_service_call.and_return(double(paid?: true))
        service.call
      end
    end

    shared_examples 'do not pay bill' do
      specify do
        expect(PayBill).not_to receive_service_call
        service.call
      end
    end

    context 'subscription should not be inactive because of billing' do
      let(:credit_card) { create :credit_card }
      let(:site) { create :site, user: credit_card.user }

      before { stub_cyber_source :purchase }

      specify 'tries to charge users 3 days before the subscription ends', freeze: '2017-07-01 11:00 UTC' do
        ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call
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
      let!(:bill_without_credit_card) { create :bill }

      before { bill_without_credit_card.credit_card.destroy }

      specify do
        expect(report).to receive(:cannot_pay)

        expect { service.call }
          .not_to change { bill_without_credit_card.reload.status }
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

    context 'subscription lifecycle simulation', freeze: '2017-01-01 10:04 UTC' do
      let!(:credit_card) { create :credit_card }
      let!(:site) { create :site }

      def change_subscription(kind)
        ChangeSubscription.new(site, { subscription: kind }, credit_card).call
        site.reload
      end

      before { stub_cyber_source :purchase }

      let(:free_bill) { site.bills[0] }
      let(:first_pro_bill) { site.bills[1] }
      let(:renewal_pro_bill) { site.bills[2] }
      let(:last_pending_pro_bill) { site.bills[3] }
      let(:last_bill) { site.bills.last }

      it 'creates correct bills' do
        change_subscription('free')

        expect(site.reload.bills.count).to eql 1

        travel_to '2017-02-01 10:04 UTC'
        service.call
        site.reload

        expect(site.bills.count).to eql 1

        change_subscription('pro')
        expect(site.active_paid_bill).to eql first_pro_bill

        expect(site.bills.count).to eql 3
        expect(site.bills.paid).to match_array([first_pro_bill])
        expect(site.bills.pending).to match_array([renewal_pro_bill])
        expect(site.bills.voided).to match_array([free_bill])

        travel_to '2017-03-01 10:04 UTC'
        expect(site).to be_capable_of :pro
        service.call
        site.reload

        travel_to site.active_paid_bill.end_date + 1.second do
          expect(site).to be_capable_of :free
          expect(site.active_paid_bill).to be_nil
        end

        travel_to '2017-03-01 10:04 UTC'

        expect(site.bills.count).to eql 4
        expect(site.bills.paid).to match_array([first_pro_bill, renewal_pro_bill])
        expect(site.bills.pending).to match_array([last_pending_pro_bill])
        expect(site.bills.voided).to match_array([free_bill])

        expect(site.active_paid_bill).to eql renewal_pro_bill

        expect(free_bill.end_date.to_s).to match '2017-02-01'

        expect(first_pro_bill.end_date.to_s).to match '2017-03-01'
        expect(renewal_pro_bill.bill_at.to_s).to match '2017-02-26'
        expect(renewal_pro_bill.end_date.to_s).to match '2017-04-01'

        travel_to renewal_pro_bill.bill_at + 1.second
        service.call

        expect(last_bill.start_date.to_s).to match '2017-04-01'
        expect(last_bill.end_date.to_s).to match '2017-05-01'
      end
    end
  end
end
