require 'spec_helper'

describe PaymentMethodsController, '#index' do
  let!(:site) { create(:site, :with_user, :free_subscription) }
  let!(:user) { site.users.first }
  let!(:payment_methods) { create_list :payment_method, 2, user: user }

  before do
    stub_current_user(user)
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  context 'when user has no payment methods' do
    let!(:payment_methods) { [] }

    it 'returns an empty array' do
      get :index, site_id: site.id

      expect(response.body).to eq({ payment_methods: [] }.to_json)
    end
  end

  context 'when user has payment methods' do
    it 'returns an array of payment methods' do
      get :index, site_id: site.id

      payment_method_ids = JSON.parse(response.body)['payment_methods'].map { |method| method['id'] }

      expect(payment_method_ids).to eq(user.payment_methods.map(&:id))
    end

    context 'without a site_id as a parameter' do
      it 'returns an array of user payment methods' do
        get :index

        expect(response).to be_success
      end
    end

    it 'sets current_site_payment_method key to true if the site uses the payment for its subscription' do
      subscription = double('subscription', payment_method_id: user.payment_methods.first.id)
      site.stub current_subscription: subscription
      user.stub_chain :sites, find: site

      get :index, site_id: site.id

      current_payment_method = JSON.parse(response.body)['payment_methods'].select { |method| method['current_site_payment_method'] }

      expect(current_payment_method.size).to eq(1)
      expect(current_payment_method.first['id']).to eq(user.payment_methods.first.id)
    end
  end
end

describe PaymentMethodsController, '#update' do
  let(:site) { create(:site, :with_user) }
  let(:user) { site.users.first }

  before do
    stub_current_user user
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  context 'updating a payment detail' do
    let(:payment_method) { create(:payment_method, user: user) }
    let(:data) { PaymentForm.new({}).to_hash }
    let(:put_params) do
      {
        id: payment_method.id,
        payment_method_details: {},
        billing: { plan: 'pro', schedule: 'monthly' },
        site_id: site.id
      }
    end
    before do
      Site.any_instance.stub(has_script_installed?: true)
      allow(CyberSourceCreditCard).to receive(:new)
        .with(payment_method: payment_method, data: data)
        .and_return(PaymentMethodDetails.new)
    end

    it 'changes the subscription with the correct payment method and detail' do
      expect(CyberSourceCreditCard)
        .to receive(:new)
        .with(payment_method: payment_method, data: data)
        .and_return(PaymentMethodDetails.new)
      put :update, put_params
    end
  end
end
