require 'spec_helper'

describe SubscriptionSerializer do
  let(:user) { create(:user) }

  describe "amounts" do
    let(:serializer) { SubscriptionSerializer.new(Subscription::Pro.new, scope: user) }

    describe "#yearly_amount" do
      it "delegates to the subscriptions estimated amount" do
        expect(Subscription::Pro).to receive(:estimated_price).with(user, :yearly)
        serializer.yearly_amount
      end
    end

    describe "#monthly_amount" do
      it "delegates to the subscriptions estimated amount" do
        expect(Subscription::Pro).to receive(:estimated_price).with(user, :monthly)
        serializer.monthly_amount
      end
    end
  end
end
