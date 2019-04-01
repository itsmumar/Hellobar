describe InitializeStripeAndSubscribe, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, :free_subscription, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:params) { { plan: 'growth', schedule: 'monthly', stripeToken: 'tok_br' } }
  let(:subscription_to_return) { Stripe::Subscription.retrieve('sub_ElNmPXbnj5qx2s') }
  let(:customer_to_return) { Stripe::Customer.retrieve('cus_ElNmwwy40tItiK') }

  before do
    WebMock.allow_net_connect!
    allow(Stripe::Customer).to receive(:create).and_return(customer_to_return)
    allow(Stripe::Subscription).to receive(:create).and_return(subscription_to_return)
    allow(Stripe::Subscription).to receive(:update).and_return(subscription_to_return)
  end

  describe '#when user has stripe token' do
    context 'select growth monthly plan' do
      it 'create customer and subscription' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Growth'
        expect(site.current_subscription.schedule).to eql 'monthly'
      end
    end

    context 'select growth yearly plan' do
      let(:params) { { plan: 'growth', schedule: 'yearly', stripeToken: 'tok_br' } }
      it 'create customer' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Growth'
        expect(site.current_subscription.schedule).to eql 'yearly'
      end
    end

    context 'select elite monthly plan' do
      let(:params) { { plan: 'elite', schedule: 'monthly', stripeToken: 'tok_br' } }
      it 'create customer' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Elite'
        expect(site.current_subscription.schedule).to eql 'monthly'
      end
    end

    context 'select elite yearly plan' do
      let(:params) { { plan: 'elite', schedule: 'yearly', stripeToken: 'tok_br' } }
      it 'create customer' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Elite'
        expect(site.current_subscription.schedule).to eql 'yearly'
      end
    end
  end

  describe '#when user has not stripe token and have stripe_customer_id' do
    before do
      user.stripe_customer_id = 'cus_ElNmwwy40tItiK'
    end

    context 'select growth monthly plan' do
      let(:params) { { plan: 'growth', schedule: 'monthly' } }
      it 'retreive customer and change subscription' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Growth'
        expect(site.current_subscription.schedule).to eql 'monthly'
      end
    end

    context 'select growth yearly plan' do
      let(:params) { { plan: 'growth', schedule: 'yearly' } }
      it 'retreive customer and change subscription' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Growth'
        expect(site.current_subscription.schedule).to eql 'yearly'
      end
    end

    context 'select elite monthly plan' do
      let(:params) { { plan: 'elite', schedule: 'monthly' } }
      it 'retreive customer and change subscription' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Elite'
        expect(site.current_subscription.schedule).to eql 'monthly'
      end
    end

    context 'select elite yearly plan' do
      let(:params) { { plan: 'elite', schedule: 'yearly' } }
      it 'retreive customer and change subscription' do
        InitializeStripeAndSubscribe.new(params, user, site).call
        expect(user.stripe_customer_id).to eql 'cus_ElNmwwy40tItiK'
        expect(site.current_subscription.stripe_subscription_id).not_to be_nil
        expect(site.current_subscription.type).to eql 'Subscription::Elite'
        expect(site.current_subscription.schedule).to eql 'yearly'
      end
    end
  end
end
