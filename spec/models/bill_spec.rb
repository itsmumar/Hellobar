require 'spec_helper'
require 'payment_method_details'

describe Bill do
  fixtures :all
  set_fixture_class payment_method_details: PaymentMethodDetails # pluralized class screws up naming convention

  it "should not let create a negative bill" do
    lambda{Bill.create(:amount=>-1)}.should raise_error(Bill::InvalidBillingAmount)
  end

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
    bill.status_set_at.should be_within(2).of(Time.now)
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

  it "should return the payment details of the successful billing attempt" do
    bill = bills(:pro_bill)
    details = payment_method_details(:always_successful_details)

    bill.paid_with_payment_method_detail.should == details
  end

  describe Bill::Recurring do
    it "should create the next bill once paid" do
      subscription = subscriptions(:zombo_subscription)
      Bill.destroy_all
      subscription.bills(true).length.should == 0
      june = Time.parse("2014-06-10")
      bill_at = Time.parse("2014-06-11")
      july = Time.parse("2014-07-10")
      aug = Time.parse("2014-08-10")
      subscription.should be_monthly
      bill = Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 1)
      subscription.bills(true).length.should == 1
      bill.paid!
      subscription.bills(true).length.should == 2
      bill1 = subscription.bills[0]
      bill1.should be_paid
      bill1.start_date.should == june
      bill1.end_date.should == july
      bill2 = subscription.bills[1]
      bill2.should be_pending
      bill2.start_date.should == july
      bill2.bill_at.should == Bill::Recurring.next_month(bill_at)
      bill2.end_date.should == aug
    end

    it "should return the correct date for next_month" do
      Bill::Recurring.next_month(Time.parse("2014-12-30")).strftime("%Y-%m-%d").should == "2015-01-30"
      Bill::Recurring.next_month(Time.parse("2015-01-30")).strftime("%Y-%m-%d").should == "2015-02-28"
      Bill::Recurring.next_year(Time.parse("2014-12-30")).strftime("%Y-%m-%d").should == "2015-12-30"
      Bill::Recurring.next_year(Time.parse("2016-02-29")).strftime("%Y-%m-%d").should == "2017-02-28"
    end
  end

  describe "attempt_billing!" do
    it "should call payment_method.pay if the subscription requires_payment_method" do
      bill = bills(:now_bill)
      bill.subscription.payment_method = payment_methods(:always_successful)
      PaymentMethod.any_instance.should_receive(:pay).with(bill)
      bill.attempt_billing!
    end

    it "should mark it as paid if the subscription does not require a payment method" do
      bill = bills(:free_bill)
      PaymentMethod.any_instance.should_not_receive(:pay).with(bill)
      bill.attempt_billing!
    end
  end

  describe "problem_with_payment" do
    it "should return false if paid" do
      bills(:paid_bill).problem_with_payment?.should == false
    end

    it "should return false if voided" do
      bills(:voided_bill).problem_with_payment?.should == false
    end

    it "should return false if amount is zero" do
      bill = bills(:free_bill)
      bill.should_bill?.should == true
      bill.problem_with_payment?.should == false
    end

    it "should return true if pending and past due" do
      bill = bills(:past_due_bill)
      bill.should_bill?.should == true
      bill.past_due?.should == true
      bill.problem_with_payment?.should == true
    end

    it "should return false if due, but haven't tried billing yet" do
      bill = bills(:past_due_bill)
      # Get around destroying read-only records
      BillingAttempt.connection.execute("DELETE FROM #{BillingAttempt.table_name}")
      bill.should_bill?.should == true
      bill.past_due?.should == true
      bill.problem_with_payment?.should == false
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
    Bill.delete_all
    subscription.active_bills(true).length.should == 0
    # Add a bill after
    Bill.create!(subscription: subscription, start_date: now+15.days, end_date: now+45.days, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add a bill before
    Bill.create!(subscription: subscription, start_date: now-45.days, end_date: now-15.days, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add a bill during time, but voided
    Bill.create!(subscription: subscription, start_date: now, end_date: now+30.days, status: :voided, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add an active bill
    Bill.create!(subscription: subscription, start_date: now, end_date: now+30.days, amount: 1)
    subscription.active_bills(true).length.should == 1
  end
end

describe PaymentMethod do
  fixtures :all

  describe "pay" do
    it "should attempt to charge the bill with the payment method" do
      payment_method = payment_methods(:always_successful)
      bill = bills(:now_bill)
      AlwaysSuccessfulPaymentMethodDetails.any_instance.should_receive(:charge).with(bill.amount)
      payment_method.pay(bill)
    end

    it "should mark the bill as paid if successul" do
      bill = bills(:now_bill)
      payment_methods(:always_successful).pay(bill).should be_success
      bill.should be_paid
    end

    it "should not mark the bill as paid if failed" do
      bill = bills(:now_bill)
      payment_methods(:always_fails).pay(bill).should_not be_success
      bill.should_not be_paid
    end

    it "should create a BillingAttempt either way" do
      billing_attempt = payment_methods(:always_successful).pay(bills(:now_bill))
      billing_attempt.should_not be_nil
      billing_attempt.should be_persisted
      billing_attempt.payment_method_details.should_not be_nil
      billing_attempt.bill.should_not be_nil
      billing_attempt.response.should_not be_nil
      billing_attempt.should be_success
      # failure
      billing_attempt = payment_methods(:always_fails).pay(bills(:now_bill))
      billing_attempt.should_not be_nil
      billing_attempt.should be_persisted
      billing_attempt.payment_method_details.should_not be_nil
      billing_attempt.bill.should_not be_nil
      billing_attempt.response.should_not be_nil
      billing_attempt.should_not be_success
    end

    it "should raise an error if no payment_method_details" do
      lambda{PaymentMethod.new.pay(bills(:now_bill))}.should raise_error(PaymentMethod::MissingPaymentDetails)
    end
  end
end
