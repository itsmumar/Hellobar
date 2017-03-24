require 'spec_helper'

describe Subscribable, '#subscription_bill_and_status' do
  controller do
    include Subscribable
  end

  it 'returns the bill, updated site, and successful status when successful' do
    bill = double 'bill'
    allow(controller).to receive(:update_subscription).and_return([true, bill])
    site = create(:site)
    serializer = double 'SiteSerializer'
    allow(SiteSerializer).to receive(:new).and_return(serializer)

    expect(controller.subscription_bill_and_status(site, 'payment_method', 'billing_params', nil))
      .to eq(bill: bill, site: serializer, is_upgrade: true, status: :ok)
  end

  it 'returns errors and an unprocessable_entity status when NOT successful' do
    bill = Bill.new
    bill.errors.add(:status, 'oops')
    allow(controller).to receive(:update_subscription).and_return([false, bill])

    expect(controller.subscription_bill_and_status('site', 'payment_method', 'billing_params', nil))
      .to eq(errors: bill.errors.full_messages, status: :unprocessable_entity)
  end

  it 'tracks changes to subscription' do
    bill = double 'bill'
    allow(controller).to receive(:update_subscription).and_return([true, bill])
    site = create(:site)
    serializer = double 'SiteSerializer'
    allow(SiteSerializer).to receive(:new).and_return(serializer)

    allow(controller).to receive(:track_upgrade)
    expect(Analytics).to receive(:track).with(:site, site.id, :change_sub, anything)

    expect(controller.subscription_bill_and_status(site, 'payment_method', 'billing_params', nil))
      .to eq(bill: bill, site: serializer, is_upgrade: true, status: :ok)
  end
end

describe Subscribable, '#build_subscription_instance' do
  controller do
    include Subscribable
  end

  it 'builds a free subscription instance properly' do
    billing_params = { plan: 'free', schedule: 'yearly' }

    expect(controller.build_subscription_instance(billing_params).class).to eq(Subscription::Free)
  end

  it 'builds a pro subscription instance properly' do
    billing_params = { plan: 'pro', schedule: 'yearly' }

    expect(controller.build_subscription_instance(billing_params).class).to eq(Subscription::Pro)
  end

  it 'builds an enterprise subscription instance properly' do
    billing_params = { plan: 'enterprise', schedule: 'yearly' }

    expect(controller.build_subscription_instance(billing_params).class).to eq(Subscription::Enterprise)
  end

  it 'sets the schedule to monthly properly' do
    billing_params = { plan: 'pro', schedule: 'monthly' }

    expect(controller.build_subscription_instance(billing_params).schedule).to eq('monthly')
  end

  it 'sets the schedule to yearly properly' do
    billing_params = { plan: 'pro', schedule: 'yearly' }

    expect(controller.build_subscription_instance(billing_params).schedule).to eq('yearly')
  end
end

describe Subscribable, '#update_subscription' do
  controller do
    include Subscribable
  end

  describe 'recovering from a failed payment' do
    let(:site) { create(:site, :with_user, :pro) }
    let(:billing_params) { { plan: 'pro', schedule: 'yearly', trial_period: '60' } }
    let(:pro) { site.subscriptions.first }

    it 'removes the branding from pro subscriptions' do
      site.change_subscription(pro, create(:payment_method, :fails))
      expect(site.capabilities(true).remove_branding?).to be(false)
      expect(site.site_elements.all?(&:show_branding)).to be(true)

      controller.update_subscription(site, create(:payment_method), billing_params)
      expect(site.capabilities(true).remove_branding?).to be(true)
      expect(site.site_elements.none?(&:show_branding)).to be(true)
    end
  end

  context 'trial_period' do
    it 'translates the trial_period to days' do
      billing_params = { plan: 'pro', schedule: 'yearly', trial_period: '60' }
      site = create(:site)
      expect(site).to receive(:change_subscription).with(anything, nil, 60.days)
      controller.update_subscription(site, nil, billing_params)
    end

    it 'translates the trial_period to nil if not given' do
      billing_params = { plan: 'pro', schedule: 'yearly' }
      site = create(:site)
      expect(site).to receive(:change_subscription).with(anything, nil, nil)
      controller.update_subscription(site, nil, billing_params)
    end
  end
end
