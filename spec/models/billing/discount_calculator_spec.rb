describe DiscountCalculator do
  let(:user) { create(:user) }

  before do
    allow(Subscription::Pro).to receive(:defaults).and_return(monthly_amount: 15.0, discounts: [
      DiscountRange.new(2, 0, 1, 10),
      DiscountRange.new(2, 1, 2, 20),
      DiscountRange.new(nil, 2, 3, 30)
    ])
  end

  def create_subscription_for user
    subscription = create(:subscription, :pro, schedule: :monthly, user: user)
    subscription.payment_method.update(user: user)
    subscription.site.users << user
    subscription
  end

  describe '#current_discount' do
    context 'there is only one Subscription' do
      it 'returns the first amount' do
        subscription = create_subscription_for(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(1)
      end
    end

    context 'the first tier has been filled' do
      before do
        create_subscription_for(user)
        create_subscription_for(user)
      end

      it 'returns the amount for the second tier' do
        subscription = create_subscription_for(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(2)
      end

      it "returns the amount for the next tier for subscriptions that aren't persisted" do
        subscription = Subscription::Pro.new(schedule: :monthly)
        calculator = DiscountCalculator.new(subscription, user)
        expect(calculator.current_discount).to eq(2)
      end
    end

    context 'all tiers have been filled' do
      before do
        create_subscription_for(user)
        create_subscription_for(user)
        create_subscription_for(user)
        create_subscription_for(user)
      end

      it 'returns the last amount' do
        subscription = create_subscription_for(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(3)
      end
    end
  end
end
