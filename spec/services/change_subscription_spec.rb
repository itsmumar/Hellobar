describe ChangeSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:payment_method) { create :payment_method, user: user }
  let(:params) { { plan: 'pro', schedule: 'yearly' } }
  let(:service) { ChangeSubscription.new(site, payment_method, params) }
  let(:last_subscription) { Subscription.last }

  before { stub_gateway_methods(:purchase) }
  before { create :subscription, :free, payment_method: payment_method, site: site }

  describe '.call' do
    it 'creates a bill for current period' do
      expect { service.call }.to change(site.bills.where(bill_at: Time.current), :count).to(1)
    end

    it 'creates a bill for next period' do
      expect { service.call }.to change(site.bills.where(bill_at: 1.year.from_now - 1.hour), :count).to(1)
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
        to_plan: 'Pro',
        to_schedule: 'yearly',
        from_plan: 'Free',
        from_schedule: 'monthly',
      }
      expect(Analytics).to receive(:track).with(:site, site.id, :change_sub, props)
      service.call
    end

    context 'with monthly schedule' do
      let(:params) { { plan: 'pro', schedule: 'monthly' } }

      it 'creates a bill for next period' do
        expect { service.call }.to change(site.bills.where(bill_at: 1.month.from_now - 1.hour), :count).to(1)
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
      let(:params) { { plan: 'enterprise', schedule: 'yearly' } }

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
  end
end
