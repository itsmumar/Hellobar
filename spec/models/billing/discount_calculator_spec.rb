require 'spec_helper'

describe DiscountCalculator do
  let(:user) { create(:user) }
  before do
    allow(Subscription::Pro).to receive(:defaults).and_return(discounts: [
      DiscountRange.new(2, 0, 1, 10),
      DiscountRange.new(2, 1, 2, 20),
      DiscountRange.new(nil, 2, 3, 30)
    ])
  end

  def create_sub_for_user(u)
    subscription = create(:pro_subscription, schedule: :monthly)
    subscription.payment_method.update(user: u)
    subscription.site.users << u
    subscription
  end

  describe '#current_discount' do
    context 'there is only one Subscription' do
      it 'returns the first amount' do
        subscription = create_sub_for_user(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(1)
      end
    end

    context 'the first tier has been filled' do
      before do
        create_sub_for_user(user)
        create_sub_for_user(user)
      end

      it 'returns the amount for the second tier' do
        subscription = create_sub_for_user(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(2)
      end

      it "returns the amount for the next tier for subs that aren't persisted" do
        subscription = Subscription::Pro.new(schedule: :monthly)
        calculator = DiscountCalculator.new(subscription, user)
        expect(calculator.current_discount).to eq(2)
      end
    end

    context 'all tiers have been filled' do
      before do
        create_sub_for_user(user)
        create_sub_for_user(user)
        create_sub_for_user(user)
        create_sub_for_user(user)
      end

      it 'returns the last amount' do
        subscription = create_sub_for_user(user)
        calculator = DiscountCalculator.new(subscription)
        expect(calculator.current_discount).to eq(3)
      end
    end
  end
end
