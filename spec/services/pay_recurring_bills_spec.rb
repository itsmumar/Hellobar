describe PayRecurringBills do
  describe '.bills' do
    let!(:bills) do
      [
        create(:bill, bill_at: 1.year.ago),
        create(:bill, bill_at: 27.days.ago),
        create(:bill, bill_at: 1.day.ago),
        create(:bill, bill_at: Time.current)
      ]
    end

    let!(:future_bill) { create(:bill, bill_at: 1.day.from_now) }

    it 'includes bills within period from 27 days ago till today' do
      expect(PayRecurringBills.bills).to match_array bills
      expect(PayRecurringBills.bills).not_to include future_bill
    end
  end

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
      create :bill, :free
      expect(report).to receive(:start)
      expect(report).to receive(:count).exactly(1).times
      expect(report).to receive(:finish)
      expect(report).to receive(:email)
      service.call
    end

    context 'with zero amount bill' do
      let!(:zero_amount_bill) { create :bill, :free }

      specify do
        expect { service.call }
          .to change { zero_amount_bill.reload.status }.to(Bill::PAID)
      end

      include_examples 'pay bill'
    end

    context 'with bill which has no site anymore' do
      let!(:bill_without_site) { create :bill }
      before { bill_without_site.site.delete }

      specify do
        expect(report).to receive(:void).with(bill_without_site)

        expect { service.call }
          .to change { bill_without_site.reload.status }.to(Bill::VOIDED)
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

      context 'when its end_date < 27.days.ago' do
        let!(:bill_without_credit_card) { create :bill, end_date: 28.days.ago }

        specify do
          expect(report).to receive(:downgrade)
          expect(report).not_to receive(:attempt)

          expect(DowngradeSiteToFree)
            .to receive_service_call
            .with(bill_without_credit_card.site)

          expect { service.call }
            .to change { bill_without_credit_card.reload.status }
            .to(Bill::VOIDED)
        end
      end
    end

    context 'with bill in the future' do
      let!(:bill) { create :bill, bill_at: 1.month.from_now }

      specify do
        expect(report).not_to receive(:count)
        expect { service.call }
          .not_to change { bill.reload.status }
      end
    end

    context 'with payable bill' do
      let!(:bill) { create :bill }

      before { stub_cyber_source :purchase }

      specify do
        expect(report).to receive(:success)

        expect { service.call }
          .to change { bill.reload.status }.to Bill::PAID
      end

      include_examples 'pay bill'

      context 'when bill had payment problem before' do
        let!(:bill) { create :bill, :problem }

        specify do
          expect { service.call }
            .to change { bill.reload.status }.to Bill::PAID
        end

        include_examples 'pay bill'
      end

      context 'when unsuccessful' do
        before { stub_cyber_source :purchase, success?: false }

        specify do
          expect(report).to receive(:fail)

          expect { service.call }
            .to change { bill.reload.status }.to Bill::FAILED
        end

        it 'notifies owners' do
          expect { service.call }
            .to have_enqueued_job
            .with('BillingMailer', 'could_not_charge', 'deliver_now', bill)
        end
      end

      context 'when exception' do
        let(:exception) { RuntimeError.new('error') }
        before { expect(PayBill).to receive_service_call.and_raise exception }

        specify do
          expect(report).to receive(:exception).with(exception)
          expect(report).to receive(:interrupt).with(exception)

          expect { service.call }.to raise_error exception
        end

        context 'when killed with a SignalException' do
          let(:exception) { Exception.new('kill') }

          specify do
            expect(report).not_to receive(:exception)
            expect(report).to receive(:interrupt).with(exception)

            expect { service.call }.to raise_error exception
          end
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

      let(:first_pro_bill) { site.bills[0] }
      let(:renewal_pro_bill) { site.bills[1] }
      let(:last_pending_pro_bill) { site.bills[2] }
      let(:last_bill) { site.bills.last }

      def travel_to_next_billing_date
        travel_to 1.month.from_now + 1.day
      end

      def bills
        site.reload.bills
      end

      after { travel_back }

      context 'when just signed up' do
        before { change_subscription('free') }

        it 'does not create free bill' do
          expect(bills.count).to eql 0

          travel_to_next_billing_date
          service.call

          expect(bills.count).to eql 0
        end

        context 'when upgraded to pro next month' do
          before do
            travel_to_next_billing_date
            service.call
            change_subscription('pro')
          end

          it 'creates right bills' do
            expect(site.active_paid_bill).to eql first_pro_bill

            expect(bills.count).to eql 2
            expect(bills.paid).to match_array([first_pro_bill])
            expect(bills.pending).to match_array([renewal_pro_bill])
            expect(bills.voided).to be_empty
          end

          context 'a month later' do
            before { travel_to 1.month.from_now }

            it 'still on Pro' do
              expect(site).to be_capable_of :pro
              service.call
              site.reload

              expect(site).to be_capable_of :pro
              expect(bills.count).to eql 3
            end

            context 'when expires' do
              before do
                service.call
                travel_to_next_billing_date
              end

              it 'fallbacks to Free' do
                expect(site).to be_capable_of :free
                service.call
                expect(site).to be_capable_of :pro
              end
            end

            it 'has correct bills' do
              service.call
              expect(site.bills.count).to eql 3
              expect(site.bills.paid).to match_array([first_pro_bill, renewal_pro_bill])
              expect(site.bills.pending).to match_array([last_pending_pro_bill])
              expect(site.bills.voided).to be_empty

              expect(site.active_paid_bill).to eql renewal_pro_bill

              expect(first_pro_bill.end_date.to_s).to match '2017-03-02'
              expect(renewal_pro_bill.bill_at.to_s).to match '2017-02-27'
              expect(renewal_pro_bill.end_date.to_s).to match '2017-04-02'

              travel_to_next_billing_date
              service.call

              expect(last_bill.start_date.to_s).to match '2017-04-02'
              expect(last_bill.end_date.to_s).to match '2017-05-02'
            end
          end
        end
      end

      context 'when there is a past due bill' do
        before { change_subscription('pro') }
        let(:pending_bill) { site.bills.pending.last }

        it 'tries to charge 10 times every 3rd day' do
          stub_cyber_source :purchase, success?: false

          travel_to pending_bill.bill_at

          expect { service.call }
            .to change { pending_bill.reload.status }
            .from(Bill::PENDING)
            .to(Bill::FAILED)

          (1..26).each do |nth|
            travel_to pending_bill.bill_at + nth.day
            service.call
          end
          expect(pending_bill.billing_attempts.failed.count).to eql 9

          travel_to pending_bill.bill_at + 27.days
          service.call

          expect(pending_bill.billing_attempts.failed.count).to eql 10

          travel_to pending_bill.bill_at + 30.days

          service.call

          expect(pending_bill.reload).to be_voided
        end
      end
    end
  end
end
