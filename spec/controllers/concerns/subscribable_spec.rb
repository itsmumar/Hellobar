require 'spec_helper'

describe Subscribable, '#subscription_bill_and_status' do
  fixtures :all

  controller do
    include Subscribable
  end

  it 'returns the bill, updated site, and successful status when successful' do
    bill = double 'bill'
    controller.stub update_subscription: [true, bill]
    site = sites(:horsebike)
    serializer = double 'SiteSerializer'
    SiteSerializer.stub new: serializer

    controller.subscription_bill_and_status(site, 'payment_method', 'billing_params', nil).should == { bill: bill, site: serializer, is_upgrade: true, status: :ok }
  end

  it 'returns errors and an unprocessable_entity status when NOT successful' do
    bill = Bill.new
    bill.errors.add(:status, 'oops')
    controller.stub update_subscription: [false, bill]

    controller.subscription_bill_and_status('site', 'payment_method', 'billing_params', nil).should == { errors: bill.errors.full_messages, status: :unprocessable_entity }
  end

  it 'tracks changes to subscription' do
    bill = double 'bill'
    controller.stub update_subscription: [true, bill]
    site = sites(:horsebike)
    serializer = double 'SiteSerializer'
    SiteSerializer.stub new: serializer

    allow(controller).to receive(:track_upgrade)
    expect(Analytics).to receive(:track).with(:site, site.id, :change_sub, anything)

    controller.subscription_bill_and_status(site, 'payment_method', 'billing_params', nil).should == { bill: bill, site: serializer, is_upgrade: true, status: :ok }
  end
end

describe Subscribable, '#build_subscription_instance' do
  controller do
    include Subscribable
  end

  it 'builds a free subscription instance properly' do
    billing_params = { plan: 'free', schedule: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Free
  end

  it 'builds a pro subscription instance properly' do
    billing_params = { plan: 'pro', schedule: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Pro
  end

  it 'builds an enterprise subscription instance properly' do
    billing_params = { plan: 'enterprise', schedule: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Enterprise
  end

  it 'sets the schedule to monthly properly' do
    billing_params = { plan: 'pro', schedule: 'monthly' }

    controller.build_subscription_instance(billing_params).schedule.should == 'monthly'
  end

  it 'sets the schedule to yearly properly' do
    billing_params = { plan: 'pro', schedule: 'yearly' }

    controller.build_subscription_instance(billing_params).schedule.should == 'yearly'
  end
end

describe Subscribable, '#update_subscription' do
  fixtures :all

  controller do
    include Subscribable
  end

  describe 'recovering from a failed payment' do
    let(:site) { sites(:horsebike) }
    let(:billing_params) { { plan: 'pro', schedule: 'yearly', trial_period: '60' } }
    let(:pro) { Subscription::Pro.new(user: users(:joey), site: site) }

    it 'removes the branding from pro subscriptions' do
      site.change_subscription(pro, payment_methods(:always_fails))
      expect(site.capabilities(true).remove_branding?).to be(false)
      expect(site.site_elements.all?(&:show_branding)).to be(true)

      controller.update_subscription(site, payment_methods(:always_successful), billing_params)
      expect(site.capabilities(true).remove_branding?).to be(true)
      expect(site.site_elements.none?(&:show_branding)).to be(true)
    end
  end

  context 'trial_period' do
    it 'translates the trial_period to days' do
      billing_params = { plan: 'pro', schedule: 'yearly', trial_period: '60' }
      site = sites(:horsebike)
      site.should_receive(:change_subscription).with(anything, nil, 60.days)
      controller.update_subscription(site, nil, billing_params)
    end

    it 'translates the trial_period to nil if not given' do
      billing_params = { plan: 'pro', schedule: 'yearly' }
      site = sites(:horsebike)
      site.should_receive(:change_subscription).with(anything, nil, nil)
      controller.update_subscription(site, nil, billing_params)
    end
  end
end
