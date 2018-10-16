describe ProfitwellAnalyticsAdapter do
  let(:params) { Hash[foo: 'bar'] }
  let(:profitwell_gateway) { instance_double(ProfitwellGateway) }
  let(:adapter) { ProfitwellAnalyticsAdapter.new }

  let(:user) { double('user') }
  let(:subscription) { create :subscription, :pro }
  let(:previous_subscription) { create :subscription, :free }

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

    before { allow(profitwell_gateway).to receive(:create_subscription) }
    before { allow(profitwell_gateway).to receive(:churn_subscription) }

    %w[downgraded_subscription upgraded_subscription].each do |event|
      context "with #{ event } event" do
        let(:event) { event }

        context 'when previous_subscription is nil' do
          let(:previous_subscription) { nil }

          it 'calls create_subscription' do
            expect(profitwell_gateway)
              .to receive(:create_subscription)
              .with(user, subscription)

            track
          end

          it 'does not call churn_subscription' do
            expect(profitwell_gateway)
              .not_to receive(:churn_subscription)

            track
          end
        end

        context 'and previous_subscription is not nil' do
          let(:previous_subscription) { create :subscription, :free }

          it 'calls create_subscription' do
            expect(profitwell_gateway)
              .to receive(:create_subscription)
              .with(user, subscription)

            track
          end

          it 'calls churn_subscription' do
            expect(profitwell_gateway)
              .to receive(:churn_subscription)
              .with(previous_subscription.id, subscription.created_at)

            track
          end
        end
      end
    end
  end
end
