require 'spec_helper'

describe Subscribable, '#subscription_bill_and_status' do
  controller do
    include Subscribable
  end

  it 'returns the bill and successful status when successful' do
    bill = double 'bill'
    controller.stub update_subscription: [true, bill]

    controller.subscription_bill_and_status('site', 'payment_method', 'billing_params').should == { bill: bill, status: :ok }
  end

  it 'returns errors and an unprocessable_entity status when NOT successful' do
    bill = double 'bill', errors: ['boo boo']
    controller.stub update_subscription: [false, bill]

    controller.subscription_bill_and_status('site', 'payment_method', 'billing_params').should == { errors: bill.errors, status: :unprocessable_entity }
  end
end

describe Subscribable, '#build_subscription_instance' do
  controller do
    include Subscribable
  end

  it 'builds a free subscription instance properly' do
    billing_params = { plan: 'free', cycle: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Free
  end

  it 'builds a pro subscription instance properly' do
    billing_params = { plan: 'pro', cycle: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Pro
  end

  it 'builds an enterprise subscription instance properly' do
    billing_params = { plan: 'enterprise', cycle: 'yearly' }

    controller.build_subscription_instance(billing_params).class.should == Subscription::Enterprise
  end

  it 'sets the schedule to monthly properly' do
    billing_params = { plan: 'pro', cycle: 'monthly' }

    controller.build_subscription_instance(billing_params).schedule.should == 'monthly'
  end

  it 'sets the schedule to annually properly' do
    billing_params = { plan: 'pro', cycle: 'yearly' }

    controller.build_subscription_instance(billing_params).schedule.should == 'yearly'
  end
end
