describe ChangeSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:params) { { subscription: 'pro', schedule: 'yearly' } }
  let(:service) { ChangeSubscription.new(site, params, credit_card) }
  let(:last_subscription) { Subscription.last }

  before { stub_cyber_source :purchase }
  before { change_subscription 'free' }

  def change_subscription(subscription, schedule = 'monthly', new_credit_card: nil)
    ChangeSubscription.new(
      site,
      { subscription: subscription, schedule: schedule },
      new_credit_card || credit_card
    ).call
  end

  describe '.call' do
    it 'creates a bill for current period' do
      expect { service.call }
        .to change(site.bills.where(bill_at: Time.current), :count).by(1)
    end

    it 'creates a bill for next period' do
      expect { service.call }.to change(site.bills.pending, :count).by(1)
    end

    it 'pays bill' do
      expect(PayBill).to receive_service_call.and_return(build_stubbed(:bill))
      service.call
    end

    it 'regenerates script' do
      expect { service.call }
        .to have_enqueued_job(GenerateStaticScriptJob).with(site).twice
    end

    it 'returns paid bill' do
      expect(service.call).to be_a(Bill).and be_paid
    end

    context 'with pending bills' do
      let!(:pending_bill) { create :bill, :free, subscription: site.current_subscription }

      it 'voids pending bills' do
        service.call
        expect(pending_bill.reload).to be_voided
      end
    end

    it 'sends an event to Analytics' do
      props = {
        to_subscription: 'Pro',
        to_schedule: 'yearly',
        from_subscription: 'Free',
        from_schedule: 'monthly'
      }
      expect(Analytics).to receive(:track).with(:site, site.id, :change_sub, props)
      service.call
    end

    it 'sends an event to Intercom' do
      expect { service.call }
        .to have_enqueued_job(SendEventToIntercomJob)
        .with('changed_subscription', site: site, user: user)
    end

    context 'without credit card' do
      let(:credit_card) { nil }

      it 'raises PayBill::Error' do
        expect { service.call }
          .to raise_error PayBill::Error, 'could not pay bill without credit card'
      end
    end

    context 'with monthly schedule' do
      let(:params) { { subscription: 'pro', schedule: 'monthly' } }

      it 'creates a bill for next period' do
        expect { service.call }.to change(site.bills.pending, :count).to(1)
      end
    end

    context 'upgrade to Pro' do
      it 'creates Subscription::Pro' do
        expect { service.call }
          .to change(site.subscriptions, :count)
          .by(1)
          .and change(credit_card.subscriptions, :count)
          .by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Pro
      end
    end

    context 'upgrade to enterprise' do
      let(:params) { { subscription: 'enterprise', schedule: 'yearly' } }

      it 'creates Subscription::Enterprise' do
        expect { service.call }
          .to change(site.subscriptions, :count)
          .by(1)
          .and change(credit_card.subscriptions, :count)
          .by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Enterprise
      end
    end

    context 'when error is raised during transaction' do
      it 'does not create neither a subscription nor a bill' do
        expect(PayBill).to receive_service_call.and_raise(StandardError)
        expect { service.call }
          .to raise_error(StandardError)
          .and change(Subscription, :count)
          .by(0)
          .and change(Bill, :count)
          .by(0)
      end
    end

    context 'when could not charge credit card' do
      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          expect { service.call }.to make_gateway_call(:purchase).and_fail
        }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    describe 'upgrading/downgrading' do
      def refund(bill)
        RefundBill.new(bill).call
      end

      context 'when changing to the same type' do
        before { change_subscription('pro', 'monthly') }

        it 'does not change subscription' do
          expect { change_subscription('pro', 'monthly') }
            .not_to change { site.reload.current_subscription }
        end

        it 'updates payment method' do
          site.current_subscription.update credit_card: create(:credit_card)

          expect { change_subscription('pro', 'monthly') }
            .to change { site.current_subscription.reload.credit_card }
        end

        context 'when there is a problem bill' do
          let!(:new_credit_card) { create :credit_card }
          let(:failed_bill) { site.current_subscription.bills.last }

          before do
            change_subscription('pro', 'monthly')
            failed_bill.failed!
          end

          it 'pays the failed bill' do
            expect { change_subscription('pro', 'monthly') }
              .to change(site.bills.failed, :count)
              .by(-1)
          end

          it 'uses new credit card if provided' do
            expect(failed_bill.reload.credit_card).to eql credit_card

            travel_to site.current_subscription.active_until + 1.day do
              change_subscription('pro', 'monthly', new_credit_card: new_credit_card)
              expect(failed_bill.reload.credit_card).to eql new_credit_card
            end
          end
        end
      end

      context 'when starting with Free plan' do
        before { site.current_subscription.destroy }

        it 'changes subscription and capabilities' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
          expect(site).to be_capable_of :free
        end

        it 'does not create a bill' do
          expect(PayBill).not_to receive_service_call
          expect { change_subscription('free') }.not_to change(Bill, :count)
        end
      end

      context 'when upgrading to ProManaged' do
        it 'changes subscription and capabilities' do
          expect { change_subscription('pro_managed') }
            .to change { site.reload.current_subscription }

          expect(site.current_subscription).to be_instance_of Subscription::ProManaged
          expect(site).to be_capable_of :pro_managed
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro_managed')
        end

        it 'does not create pending bill for next period' do
          expect { change_subscription('pro_managed') }
            .not_to change { site.reload.bills.pending }
        end

        it 'never expires' do
          change_subscription('pro_managed')
          travel_to 10.years.from_now do
            expect(site.current_subscription).to be_instance_of Subscription::ProManaged
            expect(site).to be_capable_of :pro_managed
          end
        end
      end

      context 'when upgrading to Pro from FreePlus' do
        before { change_subscription('free_plus') }

        it 'changes subscription and capabilities' do
          expect { change_subscription('pro') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Pro
          expect(site).to be_capable_of :pro
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro')
        end

        it 'voids free bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro')
          expect(site.previous_subscription.bills).to match_array([kind_of(Bill)])
          expect(site.previous_subscription.bills.first).to be_voided
        end

        context 'and then to Enterprise from Pro' do
          before { change_subscription('pro') }

          it 'changes subscription and capabilities' do
            expect { change_subscription('enterprise') }.to change { site.reload.current_subscription }
            expect(site.current_subscription).to be_instance_of Subscription::Enterprise
            expect(site).to be_capable_of :enterprise
          end

          it 'excludes a paid amount from new bill' do
            expect(change_subscription('enterprise').amount).to eql 99 - 15
          end

          it 'pays bill' do
            expect(PayBill).to receive_service_call
            change_subscription('enterprise')
          end

          context 'when a refund has been made' do
            before { stub_cyber_source :refund, :purchase }
            before { RefundBill.new(site.reload.current_subscription.bills.paid.last).call }

            it 'charges full amount' do
              expect(change_subscription('enterprise').amount).to eql 99
            end
          end
        end
      end

      context 'when downgrading to Free from Pro' do
        before { change_subscription('pro') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
        end

        it 'does not change capabilities' do
          expect { change_subscription('free') }.not_to change { site.reload.capabilities }
        end

        it 'does not pay bill' do
          expect(PayBill).not_to receive_service_call
          change_subscription('free')
        end

        it 'voids pending bill' do
          expect { change_subscription('free') }
            .to change { site.bills.voided.count }
            .by(1)
        end

        context 'when Pro subscription expires' do
          it 'changes capabilities to Free' do
            change_subscription('free')

            travel_to 1.month.from_now + 1.day do
              expect(site).to be_capable_of :free
            end
          end
        end

        it 'sends an event to Analytics' do
          props = {
            to_subscription: 'Free',
            to_schedule: 'monthly',
            from_subscription: 'Pro',
            from_schedule: 'monthly'
          }
          expect(Analytics).to receive(:track).with(:site, site.id, :change_sub, props)
          change_subscription('free')
        end

        it 'sends an event to Intercom' do
          expect { change_subscription('free') }
            .to have_enqueued_job(SendEventToIntercomJob)
            .with('changed_subscription', site: site, user: user)
        end
      end

      context 'when downgrading to Free from Enterprise' do
        before { change_subscription('enterprise') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
        end

        it 'does not change capabilities' do
          expect { change_subscription('free') }.not_to change { site.reload.capabilities }
        end

        it 'does not pay bill' do
          expect(PayBill).not_to receive_service_call
          change_subscription('free')
        end

        context 'when Pro subscription expires' do
          it 'changes capabilities to Free' do
            change_subscription('free')

            travel_to 1.month.from_now + 1.day do
              expect(site).to be_capable_of :free
            end
          end
        end
      end

      context 'when payment fails' do
        let(:last_bill) { site.reload.current_subscription.bills.with_amount.last }

        it 'returns problem bill' do
          expect {
            expect { service.call }.to make_gateway_call(:purchase).and_fail
          }.to raise_error ActiveRecord::RecordInvalid
          expect(last_bill).to be_nil
          expect(site.current_subscription).to be_instance_of Subscription::Free
          expect(site).to be_capable_of :free
        end
      end

      context 'when switching from yearly to monthly' do
        it 'does not create a negative bill' do
          yearly_bill = change_subscription('pro', 'yearly')
          expect(yearly_bill.amount).to eql Subscription::Pro.defaults[:yearly_amount]
          expect(yearly_bill).to be_paid

          monthly_bill = change_subscription('pro', 'monthly')
          expect(monthly_bill.amount).to eql Subscription::Pro.defaults[:monthly_amount]
          expect(monthly_bill.due_at).to eql yearly_bill.due_at + 1.year
          expect(monthly_bill).to be_pending
        end
      end

      context 'accidentally signed up for the annual plan' do
        before { stub_cyber_source :refund, :purchase }

        it 'sets correct bill_at, start_date and end_date' do
          yearly_bill = change_subscription('pro', 'yearly')
          refund(yearly_bill)
          monthly_bill = change_subscription('pro', 'monthly')
          expect(monthly_bill.bill_at).to eql Time.current
          expect(monthly_bill.start_date).to eql Time.current
          expect(monthly_bill.end_date).to eql 1.month.from_now
        end
      end
    end
  end
end
