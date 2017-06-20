describe UpgradeSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:payment_method) { create :payment_method, user: user }
  let(:params) { { billing: { plan: 'pro', schedule: 'yearly' } } }
  let(:service) { UpgradeSubscription.new(site, payment_method, params) }
  let(:last_subscription) { Subscription.last }
  before { stub_gateway_methods(:purchase) }

  describe '.call' do
    it 'creates a bill for current period' do
      expect { service.call }.to change(site.bills.where(bill_at: Time.current), :count).to(1)
    end

    it 'creates a bill for next period' do
      expect { service.call }.to change(site.bills.where(bill_at: 1.year.from_now - 1.hour), :count).to(1)
    end

    it 'pays bill' do
      expect(PayBill).to receive_service_call
      service.call
    end

    it 'returns paid bill' do
      expect(service.call).to be_a(Bill).and be_paid
    end

    context 'upgrade to Pro' do
      it 'creates Subscription::Pro' do
        expect { service.call }
          .to change(site.subscriptions, :count).to(1)
          .and change(payment_method.subscriptions, :count).to(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Pro
      end
    end

    context 'upgrade to enterprise' do
      let(:params) { { billing: { plan: 'enterprise', schedule: 'yearly' } } }

      it 'creates Subscription::Enterprise' do
        expect { service.call }
          .to change(site.subscriptions, :count).to(1)
          .and change(payment_method.subscriptions, :count).to(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Enterprise
      end
    end

    context 'with monthly schedule' do
      let(:params) { { billing: { plan: 'pro', schedule: 'monthly' } } }

      it 'creates a bill for next period' do
        expect { service.call }.to change(site.bills.where(bill_at: 1.month.from_now - 1.hour), :count).to(1)
      end
    end
  end
end
