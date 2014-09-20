require 'spec_helper'
require 'payment_method_details'

describe Bill do
  fixtures :all
  it "should not let you change the status once set" do
    bill = bills(:future_bill)
    bill.status.should  == :pending
    bill.voided!
    bill.status.should  == :voided
    bill = Bill.find(bill.id)
    bill.status.should  == :voided
    lambda{bill.pending!}.should raise_error(Bill::StatusAlreadySet)
    lambda{bill.paid!}.should raise_error(Bill::StatusAlreadySet)
    lambda{bill.status = :pending}.should raise_error(Bill::StatusAlreadySet)
  end
  
  it "should raise an error if you try to change the status to an invalid value" do
    bill = bills(:future_bill)
    lambda{bill.status = "foo"}.should raise_error(Bill::InvalidStatus)
  end

  it "should record when the status was set" do
    bill = bills(:future_bill)
    bill.status.should  == :pending
    bill.status_set_at.should be_nil
    bill.paid!
    bill.status_set_at.should be_within(1).of(Time.now)
  end

  it "should take the payment_method grace period into account when grace_period_allowed" do
    now = Time.now
    bill = bills(:now_bill)
    bill.grace_period_allowed?.should == true
    bill.bill_at.should be_within(5.minutes).of(now)
    bill.due_at.should == bill.bill_at
    payment_method = PaymentMethod.new
    payment_method_details = CyberSourceCreditCard.new
    payment_method.details << payment_method_details
    payment_method_details.grace_period.should > 5.minutes
    bill.due_at(payment_method).should == bill.bill_at+payment_method_details.grace_period
    bill.grace_period_allowed = false
    bill.due_at(payment_method).should == bill.bill_at
  end

  describe Bill::Recurring do
    it "should create the next bill once paid" do
      pending
    end
  end
end

describe Subscription do
  fixtures :all

  it "should return all pending bills" do
    subscription = subscriptions(:zombo_subscription)
    subscription.bills.length.should == 2
    subscription.pending_bills.length.should == 2
    subscription.bills.first.voided!
    subscription.pending_bills(true).length.should == 1
  end

  it "should return all paid bills" do
    subscription = subscriptions(:zombo_subscription)
    subscription.bills.length.should == 2
    subscription.paid_bills.length.should == 0
    subscription.bills.first.paid!
    subscription.paid_bills(true).length.should == 1
  end

  it "should return all bills active for time period" do
    now = Time.now
    subscription = subscriptions(:zombo_subscription)
    subscription.active_bills.length.should == 0
    # Add a bill after
    Bill.create!(subscription: subscription, start_date: now+15.days, end_date: now+45.days)
    subscription.active_bills(true).length.should == 0
    # Add a bill before
    Bill.create!(subscription: subscription, start_date: now-45.days, end_date: now-15.days)
    subscription.active_bills(true).length.should == 0
    # Add a bill during time, but voided
    Bill.create!(subscription: subscription, start_date: now, end_date: now+30.days, status: :voided)
    subscription.active_bills(true).length.should == 0
    # Add an active bill
    Bill.create!(subscription: subscription, start_date: now, end_date: now+30.days)
    subscription.active_bills(true).length.should == 1
  end
end
