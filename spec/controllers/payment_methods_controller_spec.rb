require 'spec_helper'

describe PaymentMethodsController, '#index' do
  fixtures :all

  before do
    stub_current_user(user)
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  let(:site) { sites(:zombo) }
  let(:user) { users(:joey) }

  it 'returns an empty array if there are no payment methods' do
    user.stub_chain :payment_methods, includes: []
    site.stub current_subscription: double('subscription', payment_method_id: nil)

    get :index, site_id: site.id

    response.body.should == { payment_methods: [] }.to_json
  end

  it 'returns an array of user payment methods' do
    get :index, site_id: site.id

    payment_method_ids = JSON.parse(response.body)['payment_methods'].map { |method| method['id'] }

    payment_method_ids.should == user.payment_methods.map(&:id)
  end

  it 'returns an array of user payment methods without a site_id as a parameter' do
    get :index

    response.should be_success
  end

  it 'sets current_site_payment_method key to true if the site uses the payment for its subscription' do
    subscription = double('subscription', payment_method_id: user.payment_methods.first.id)
    site.stub current_subscription: subscription
    user.stub_chain :sites, find: site

    get :index, site_id: site.id

    current_payment_method = JSON.parse(response.body)['payment_methods'].select { |method| method['current_site_payment_method'] }

    current_payment_method.size.should == 1
    current_payment_method.first['id'].should == user.payment_methods.first.id
  end
end

describe PaymentMethodsController, '#update' do
  fixtures :all

  before do
    stub_current_user users(:joey)
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  let(:site) { sites(:zombo) }

  context 'updating a payment detail' do
    let(:payment_method) { payment_methods(:always_successful) }
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
      CyberSourceCreditCard.should_receive(:new)
                           .with(payment_method: payment_method, data: data)
                           .and_return(PaymentMethodDetails.new)
      put :update, put_params
    end
  end
end
