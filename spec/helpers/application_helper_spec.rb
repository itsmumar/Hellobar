describe ApplicationHelper, type: :helper do
  before do
    @user = create(:user)
    allow(helper).to receive(:current_user).and_return(@user)
  end

  describe '#subscription_cost' do
    it 'delegates to Subscription.estimated_price' do
      expect(Subscription::Pro).to receive(:estimated_price).with(@user, :monthly)
      helper.subscription_cost(Subscription::Pro, :monthly)
    end

    it 'returns the monthly price for annual subscriptions' do
      allow(Subscription::Pro).to receive(:estimated_price).with(@user, :yearly).and_return(144)
      expect(helper.subscription_cost(Subscription::Pro, :yearly)).to eq('$12')
    end

    it 'rounds the results to the nearest dollar' do
      allow(Subscription::Pro).to receive(:estimated_price).with(@user, :monthly).and_return(1.49)
      expect(helper.subscription_cost(Subscription::Pro, :monthly)).to eq('$1')
    end

    it 'returns the currency string' do
      allow(Subscription::Pro).to receive(:estimated_price).with(@user, :monthly).and_return(1)
      expect(helper.subscription_cost(Subscription::Pro, :monthly)).to eq('$1')
    end
  end
end
