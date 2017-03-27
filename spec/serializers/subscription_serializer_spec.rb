describe SubscriptionSerializer do
  let(:user) { create(:user) }

  describe 'amounts' do
    let(:serializer) { SubscriptionSerializer.new(Subscription::Pro.new, scope: user) }

    describe '#yearly_amount' do
      it 'delegates to the subscriptions estimated amount' do
        expect(Subscription::Pro).to receive(:estimated_price).with(user, :yearly)
        serializer.yearly_amount
      end

      it 'returns the string representing the amount' do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.02)
        expect(serializer.yearly_amount).to eq('1.02')
      end

      it "doesn't have decimal places if it is a whole number" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.00)
        expect(serializer.yearly_amount).to eq('1')
      end
    end

    describe '#monthly_amount' do
      it 'delegates to the subscriptions estimated amount' do
        expect(Subscription::Pro).to receive(:estimated_price).with(user, :monthly)
        serializer.monthly_amount
      end

      it 'returns the string representing the amount' do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.02)
        expect(serializer.monthly_amount).to eq('1.02')
      end

      it "doesn't have decimal places if it is a whole number" do
        allow(Subscription::Pro).to receive(:estimated_price).and_return(1.00)
        expect(serializer.monthly_amount).to eq('1')
      end
    end

    describe '#payment_valid' do
      it 'is false when subscription.problem_with_payment? is true' do
        allow_any_instance_of(Subscription::Pro).to receive(:problem_with_payment?).and_return(true)
        expect(serializer.payment_valid).to eq(false)
      end

      it 'is true when subscription.problem_with_payment? is false' do
        allow_any_instance_of(Subscription::Pro).to receive(:problem_with_payment?).and_return(false)
        expect(serializer.payment_valid).to eq(true)
      end
    end
  end
end
