describe AddTrialSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:params) { { subscription: 'pro', trial_period: '7' } }
  let(:service) { AddTrialSubscription.new(site, params) }
  let(:last_subscription) { Subscription.last }

  before { ChangeSubscription.new(site, subscription: 'free').call }

  describe '.call' do
    it 'returns paid bill with zero amount' do
      bill = service.call
      expect(bill).to be_a(Bill).and be_paid
      expect(bill.amount).to eql 0
    end

    it 'creates new Subscription and changes site.current_subscription' do
      expect { service.call }
        .to change(site.subscriptions, :count).by(1)

      expect(site.current_subscription).to be_a Subscription::Pro
      expect(site).to be_capable_of :pro
    end

    it 'creates pending bill for next period' do
      bill = service.call

      next_bill = site.bills.order(:id).last

      expect(next_bill).to be_pending
      expect(next_bill.amount).to eq(site.current_subscription.amount)
      expect(next_bill.bill_at).to eq(bill.end_date - 3.days)
    end

    it 'changes capabilities to pro' do
      expect { service.call }
        .to change { site.capabilities }
      expect(site).to be_capable_of :pro
    end

    context 'when trial ends up' do
      before { service.call }

      it 'reverts back to free' do
        expect(site.current_subscription).to be_a Subscription::Pro
        Timecop.travel 7.days.from_now do
          expect(site.current_subscription).to be_a Subscription::Free
        end
      end
    end

    context 'when trial period is less than 1 day' do
      let(:params) { { subscription: 'pro', trial_period: '0' } }

      it 'raises "wrong trial period"' do
        expect { service.call }.to raise_error 'wrong trial period'
      end

      context 'or greater than 90' do
        let(:params) { { subscription: 'pro', trial_period: '91' } }

        it 'raises "wrong trial period"' do
          expect { service.call }.to raise_error 'wrong trial period'
        end
      end
    end

    context 'when error is raised during transaction' do
      it 'does not create neither a subscription nor a bill' do
        expect(Bill).to receive(:create!).and_raise(StandardError)
        expect { service.call }
          .to raise_error(StandardError)
          .and change(Subscription, :count)
          .by(0)
          .and change(Bill, :count)
          .by(0)
      end
    end
  end
end
