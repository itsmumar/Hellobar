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
    bill = double 'bill', errors: ['boo boo']
    controller.stub update_subscription: [false, bill]

    controller.subscription_bill_and_status('site', 'payment_method', 'billing_params', nil).should == { errors: bill.errors, status: :unprocessable_entity }
  end

  it "tracks changes to subscription" do
    bill = double 'bill'
    controller.stub update_subscription: [true, bill]
    site = sites(:horsebike)
    serializer = double 'SiteSerializer'
    SiteSerializer.stub new: serializer

    Analytics.should_receive(:track).with(:site, site.id, :change_sub, anything)

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
