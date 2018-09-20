describe ProfitwellAnalyticsAdapter do
  let(:params) { Hash[foo: 'bar'] }
  let(:profitwell_gateway) { instance_double(ProfitwellGateway) }
  let(:adapter) { ProfitwellAnalyticsAdapter.new }

  let(:user) { double('user') }
  let(:subscription) { double('subscription') }
  let(:previous_subscription) { double('previous_subscription') }

  before do
    allow(ProfitwellGateway)
      .to receive(:new)
      .and_return profitwell_gateway
  end

  describe '#track' do
    def track
      adapter.track(
        event: event,
        subscription: subscription,
        previous_subscription: previous_subscription,
        user: user
      )
    end

    context 'with :upgraded_subscription event' do
      let(:event) { :upgraded_subscription }

      context 'and previous_subscription is nil' do
        let(:previous_subscription) { nil }

        it 'calls create_subscription' do
          expect(profitwell_gateway)
            .to receive(:create_subscription)
            .with(user, subscription)

          track
        end
      end

      context 'and previous_subscription is not nil' do
        it 'calls update_subscription' do
          expect(profitwell_gateway)
            .to receive(:update_subscription)
            .with(subscription)

          track
        end
      end
    end

    context 'with :downgraded_subscription event' do
      let(:event) { :downgraded_subscription }

      context 'and subscription is free' do
        let(:subscription) do
          double('subscription', free?: true, site_id: 1, created_at: 'created_at')
        end

        it 'calls churn_subscription' do
          expect(profitwell_gateway)
            .to receive(:churn_subscription)
            .with(subscription.site_id, subscription.created_at)

          track
        end
      end

      context 'and previous_subscription is not nil' do
        let(:subscription) { double('subscription', free?: false) }

        it 'calls update_subscription' do
          expect(profitwell_gateway)
            .to receive(:update_subscription)
            .with(subscription)

          track
        end
      end
    end
  end
end
