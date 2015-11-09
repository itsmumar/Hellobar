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

      it "returns the string representing the amount" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.02)
        expect(serializer.yearly_amount).to eq("1.02")
      end

      it "doesn't have decimal places if it is a whole number" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.00)
        expect(serializer.yearly_amount).to eq("1")
      end
    end

    describe "#monthly_amount" do
      it "delegates to the subscriptions estimated amount" do
        expect(Subscription::Pro).to receive(:estimated_price).with(user, :monthly)
        serializer.monthly_amount
      end

      it "returns the string representing the amount" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.02)
        expect(serializer.monthly_amount).to eq("1.02")
      end

      it "doesn't have decimal places if it is a whole number" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.00)
        expect(serializer.monthly_amount).to eq("1")
      end
    end
  end
end
