describe ChangeSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:payment_method) { create :payment_method, user: user }
  let(:params) { { subscription: 'pro', schedule: 'yearly' } }
  let(:service) { ChangeSubscription.new(site, params, payment_method) }
  let(:last_subscription) { Subscription.last }

  before { stub_cyber_source :purchase }
  before { create :subscription, :free, payment_method: payment_method, site: site }

  describe '.call' do
    it 'creates a bill for current period' do
      expect { service.call }.to change(site.bills.where(bill_at: Time.current), :count).to(1)
    end

    it 'creates a bill for next period' do
      expect { service.call }.to change(site.bills.pending, :count).to(1)
    end

    it 'pays bill' do
      expect(PayBill).to receive_service_call.and_return(build_stubbed(:bill))
      service.call
    end

    it 'returns paid bill' do
      expect(service.call).to be_a(Bill).and be_paid
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

    context 'without payment method' do
      let(:payment_method) { nil }

      it 'raises PayBill::Error' do
        expect { service.call }.to raise_error PayBill::Error, 'could not pay bill without credit card'
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
          .to change(site.subscriptions, :count).by(1)
          .and change(payment_method.subscriptions, :count).by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Pro
      end
    end

    context 'upgrade to enterprise' do
      let(:params) { { subscription: 'enterprise', schedule: 'yearly' } }

      it 'creates Subscription::Enterprise' do
        expect { service.call }
          .to change(site.subscriptions, :count).by(1)
          .and change(payment_method.subscriptions, :count).by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Enterprise
      end
    end

    context 'when error is raised during transaction' do
      it 'does not create neither a subscription nor a bill' do
        expect(PayBill).to receive_service_call.and_raise(StandardError)
        expect { service.call }
          .to raise_error(StandardError)
          .and change(Subscription, :count).by(0)
          .and change(Bill, :count).by(0)
      end
    end

    describe 'upgrading/downgrading' do
      def change_subscription(subscription, schedule = 'monthly')
        ChangeSubscription.new(site, { subscription: subscription, schedule: schedule }, payment_method).call
      end

      def refund(bill)
        RefundBill.new(bill).call
      end

      context 'when starting with Free plan' do
        it 'changes subscription and capabilities' do
          expect { change_subscription('free') }.to change { site.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
          expect(site).to be_capable_of :free
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('free')
        end
      end

      context 'when upgrading to Pro from Free' do
        it 'changes subscription and capabilities' do
          expect { change_subscription('pro') }.to change { site.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Pro
          expect(site).to be_capable_of :pro
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro')
        end

        context 'and then to Enterprise from Pro' do
          before { change_subscription('pro') }

          it 'changes subscription and capabilities' do
            expect { change_subscription('enterprise') }.to change { site.current_subscription }
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
            before { RefundBill.new(site.current_subscription.bills.paid.last).call }

            it 'charges full amount' do
              expect(change_subscription('enterprise').amount).to eql 99
            end
          end
        end
      end

      context 'when downgrading to Free from Pro' do
        before { change_subscription('pro') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.current_subscription }
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

      context 'when downgrading to Free from Enterprise' do
        before { change_subscription('enterprise') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.current_subscription }
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
        let(:last_bill) { site.current_subscription.bills.last }

        it 'returns problem bill' do
          expect { change_subscription('pro') }.to make_gateway_call(:purchase).and_fail
          expect(last_bill).to be_problem
          expect(site.current_subscription).to be_instance_of Subscription::Pro
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
