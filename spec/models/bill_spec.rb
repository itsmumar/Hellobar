require 'spec_helper'
require 'payment_method_details'

module BillSpecDates
  def june
    Time.parse('2014-06-10')
  end

  def bill_at
    Time.parse('2014-06-11')
  end

  def july
    Time.parse('2014-07-10')
  end

  def aug
    Time.parse('2014-08-10')
  end

  def sep
    Time.parse('2014-09-10')
  end
end

describe Bill do
  include BillSpecDates

  fixtures :all
  set_fixture_class payment_method_details: PaymentMethodDetails # pluralized class screws up naming convention

  describe 'callbacks' do
    it 'sets the base amount before saving' do
      expect(create(:bill, amount: 10).base_amount).to eq(10)
    end
  end

  it 'should not let create a negative bill' do
    lambda { Bill.create(amount: -1) }.should raise_error(Bill::InvalidBillingAmount)
  end

  it 'should not let you change the status once set' do
    bill = bills(:future_bill)
    bill.status.should == :pending
    bill.voided!
    bill.status.should == :voided
    bill = Bill.find(bill.id)
    bill.status.should == :voided
    lambda { bill.pending! }.should raise_error(Bill::StatusAlreadySet)
    lambda { bill.paid! }.should raise_error(Bill::StatusAlreadySet)
    lambda { bill.status = :pending }.should raise_error(Bill::StatusAlreadySet)
  end

  it 'should raise an error if you try to change the status to an invalid value' do
    bill = bills(:future_bill)
    lambda { bill.status = 'foo' }.should raise_error(Bill::InvalidStatus)
  end

  it 'should record when the status was set' do
    bill = bills(:future_bill)
    bill.status.should == :pending
    bill.status_set_at.should be_nil
    bill.paid!
    bill.status_set_at.should be_within(2).of(Time.now)
  end

  it 'should take the payment_method grace period into account when grace_period_allowed' do
    now = Time.now
    bill = bills(:now_bill)
    bill.grace_period_allowed?.should == true
    bill.bill_at.should be_within(5.minutes).of(now)
    bill.due_at.should == bill.bill_at
    payment_method = PaymentMethod.new
    payment_method_details = CyberSourceCreditCard.new
    payment_method.details << payment_method_details
    payment_method_details.grace_period.should > 5.minutes
    bill.due_at(payment_method).should == bill.bill_at + payment_method_details.grace_period
    bill.grace_period_allowed = false
    bill.due_at(payment_method).should == bill.bill_at
  end

  it 'should return the payment details of the successful billing attempt' do
    bill = bills(:pro_bill)
    details = payment_method_details(:always_successful_details)

    bill.paid_with_payment_method_detail.should == details
  end

  describe '#during_trial_subscription?' do
    it 'should not be on trial subscription' do
      bill = bills(:paid_bill)
      bill.during_trial_subscription?.should be_false
    end

    it 'should be on trial subscription' do
      bill = bills(:paid_bill)
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      bill.during_trial_subscription?.should be_true
    end
  end

  describe Bill::Recurring do
    it 'should create the next bill once paid' do
      subscription = subscriptions(:zombo_subscription)
      Bill.destroy_all
      subscription.bills(true).length.should == 0
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
      bill2.bill_at.should == july
      bill2.end_date.should == aug
    end

    it 'should return the correct date for next_month' do
      Bill::Recurring.next_month(Time.parse('2014-12-30')).strftime('%Y-%m-%d').should == '2015-01-30'
      Bill::Recurring.next_month(Time.parse('2015-01-30')).strftime('%Y-%m-%d').should == '2015-02-28'
      Bill::Recurring.next_year(Time.parse('2014-12-30')).strftime('%Y-%m-%d').should == '2015-12-30'
      Bill::Recurring.next_year(Time.parse('2016-02-29')).strftime('%Y-%m-%d').should == '2017-02-28'
    end

    it 'should not be affected by a refund' do
      subscription = subscriptions(:always_successful_subscription)
      Bill.destroy_all
      subscription.bills(true).length.should == 0
      subscription.should be_monthly
      bill = Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 1)
      subscription.bills(true).length.should == 1
      bill.attempt_billing!
      bill.refund!
      subscription.bills(true).length.should == 3
      initial_bill = subscription.bills[0]
      recurring_bill = subscription.bills[1]
      refund_bill = subscription.bills[2]
      recurring_bill.paid!
      subscription.bills(true).length.should == 4
      recurring_bill2 = subscription.bills[3]
      initial_bill.should be_paid
      initial_bill.start_date.should == june
      initial_bill.end_date.should == july
      recurring_bill.should be_paid
      recurring_bill.start_date.should == july
      recurring_bill.bill_at.should == initial_bill.end_date
      recurring_bill.end_date.should == aug
      # Next recurring bill should be unaffected by refund
      recurring_bill2.should be_pending
      recurring_bill2.start_date.should == aug
      recurring_bill2.bill_at.should == recurring_bill.end_date
      recurring_bill2.end_date.should == recurring_bill2.start_date + 1.month
    end
  end

  describe 'attempt_billing!' do
    it 'calls set_final_amount' do
      bill = create(:pro_bill)
      expect(bill).to receive(:set_final_amount!)
      bill.attempt_billing!
    end

    it 'should call payment_method.pay if the bill.amount > 0' do
      bill = bills(:now_bill)
      bill.subscription.payment_method = payment_methods(:always_successful)
      PaymentMethod.any_instance.should_receive(:pay).with(bill)
      bill.attempt_billing!
    end

    it 'should mark it as paid if the bill amount is 0' do
      bill = bills(:free_bill)
      PaymentMethod.any_instance.should_not_receive(:pay).with(bill)
      bill.attempt_billing!
    end
  end

  describe 'set_final_amount' do
    before :each do
      @bill = create(:pro_bill)
      @user = users(:joey)
      @bill.site.owners << @user
      @refs = (1..3).map do
        create(:referral, sender: @user, site: @bill.site, state: 'installed', available_to_sender: true)
      end
    end

    it "sets the final amount to 0 if there's a discount for 15.0" do
      @bill.stub(:calculate_discount).and_return(15.0)
      @bill.attempt_billing!
      expect(@bill.amount).to eq(0.0)
      expect(@bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's a discount for 2.0" do
      create(:referral_coupon)
      @bill.stub(:calculate_discount).and_return(2.0)

      expect do
        @bill.attempt_billing!
      end.to change { @user.sent_referrals.redeemable_for_site(@bill.site).count }.by(-1)

      expect(@bill.amount).to eq(0.0)
      expect(@bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's no discount" do
      create(:referral_coupon)
      @bill.stub(:calculate_discount).and_return(0.0)

      expect do
        @bill.attempt_billing!
      end.to change { @user.sent_referrals.redeemable_for_site(@bill.site).count }.by(-1)

      expect(@bill.amount).to eq(0.0)
      expect(@bill.discount).to eq(15.0)
    end
  end

  describe '#calculate_discount' do
    it 'should be 0' do
      user = create(:user)
      bill = create(:pro_bill)
      bill.site.users << user

      expect(bill.calculate_discount).to eq(0)
    end

    it 'discounts to the appropriate tier' do
      user = create(:user)
      bills = []

      35.times do
        bill = create(:pro_bill, status: :paid)
        bill.site.users << user
        user.reload
        bill.subscription.payment_method.update(user: user)
        bill.update(discount: bill.calculate_discount)
        bills << bill
      end

      expected = []
      5.times { expected << 0 }
      5.times { expected << 2 }
      10.times { expected << 4 }
      10.times { expected << 6 }
      5.times { expected << 8 }
      expect(bills.map(&:discount)).to eq(expected)
    end
  end

  describe '#set_base_amount' do
    it 'sets the base amount from amount' do
      bill = build(:bill, amount: 10)
      bill.set_base_amount
      expect(bill.base_amount).to eq(10)
    end

    it 'does nothing if base amount already set' do
      bill = build(:bill, amount: 10, base_amount: 12)
      bill.set_base_amount
      expect(bill.base_amount).to eq(12)
    end
  end

  describe 'problem_with_payment' do
    it 'should return false if paid' do
      bills(:paid_bill).problem_with_payment?.should == false
    end

    it 'should return false if voided' do
      bills(:voided_bill).problem_with_payment?.should == false
    end

    it 'should return false if amount is zero' do
      bill = bills(:free_bill)
      bill.should_bill?.should == true
      bill.problem_with_payment?.should == false
    end

    it 'should return true if pending and past due' do
      bill = bills(:past_due_bill)
      bill.should_bill?.should == true
      bill.past_due?.should == true
      bill.problem_with_payment?.should == true
    end

    it "should return false if due, but haven't tried billing yet" do
      bill = bills(:past_due_bill)
      pm = payment_methods(:joeys)
      # Get around destroying read-only records
      BillingAttempt.connection.execute("DELETE FROM #{BillingAttempt.table_name}")
      bill.should_bill?.should == true
      bill.past_due?.should == true
      bill.problem_with_payment?(pm).should == false
    end

    it 'should return true if past due and there is no payment method' do
      bill = bills(:past_due_bill)
      bill.billing_attempts.delete_all
      bill.problem_with_payment?.should == true
    end
  end
end

describe Subscription do
  fixtures :all

  it 'should return all pending bills' do
    subscription = subscriptions(:zombo_subscription)
    subscription.bills.length.should == 2
    subscription.pending_bills.length.should == 2
    subscription.bills.first.voided!
    subscription.pending_bills(true).length.should == 1
  end

  it 'should return all paid bills' do
    subscription = subscriptions(:zombo_subscription)
    subscription.bills.length.should == 2
    subscription.paid_bills.length.should == 0
    subscription.bills.first.paid!
    subscription.paid_bills(true).length.should == 1
  end

  it 'should return all bills active for time period' do
    now = Time.now
    subscription = subscriptions(:zombo_subscription)
    Bill.delete_all
    subscription.active_bills(true).length.should == 0
    # Add a bill after
    Bill.create!(subscription: subscription, start_date: now + 15.days, end_date: now + 45.days, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add a bill before
    Bill.create!(subscription: subscription, start_date: now - 45.days, end_date: now - 15.days, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add a bill during time, but voided
    Bill.create!(subscription: subscription, start_date: now, end_date: now + 30.days, status: :voided, amount: 1)
    subscription.active_bills(true).length.should == 0
    # Add an active bill
    Bill.create!(subscription: subscription, start_date: now, end_date: now + 30.days, amount: 1)
    subscription.active_bills(true).length.should == 1
  end
end

describe PaymentMethod do
  include BillSpecDates
  fixtures :all

  describe 'pay' do
    it 'should attempt to charge the bill with the payment method' do
      payment_method = payment_methods(:always_successful)
      bill = bills(:now_bill)
      AlwaysSuccessfulPaymentMethodDetails.any_instance.should_receive(:charge).with(bill.amount)
      payment_method.pay(bill)
    end

    it 'should mark the bill as paid if successul' do
      bill = bills(:now_bill)
      payment_methods(:always_successful).pay(bill).should be_success
      bill.should be_paid
    end

    it 'should not mark the bill as paid if failed' do
      bill = bills(:now_bill)
      payment_methods(:always_fails).pay(bill).should_not be_success
      bill.should_not be_paid
    end

    it 'should create a BillingAttempt either way' do
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

    it 'should raise an error if no payment_method_details' do
      lambda { PaymentMethod.new.pay(bills(:now_bill)) }.should raise_error(PaymentMethod::MissingPaymentDetails)
    end
  end

  describe 'refund' do
    it 'should successfully refund the billing attempt' do
      subscription = subscriptions(:always_successful_subscription)
      bill = Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 10)
      billing_attempt = subscription.payment_method.pay(bill)
      # AlwaysSuccessfulPaymentMethodDetails.any_instance.should_receive(:refund).with(bill.amount, billing_attempt.response) -- enabling this will cause a later method to fail - not sure why
      refund_bill, refund_attempt = billing_attempt.refund!
      refund_bill.amount.should == -10
      refund_bill.refunded_billing_attempt.should == billing_attempt
      refund_bill.should_not be_nil
      refund_bill.subscription.should == subscription
      refund_bill.start_date.should be_within(5).of(Time.now)
      refund_bill.bill_at.should be_within(5).of(Time.now)
      refund_bill.end_date.should == july
      refund_attempt.should be_successful
      refund_attempt.bill.should == refund_bill
      refund_attempt.payment_method_details.should == subscription.payment_method.current_details
    end

    it 'should let you do a partial refund' do
      subscription = subscriptions(:always_successful_subscription)
      billing_attempt = subscription.payment_method.pay(Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 10))
      refund_bill, refund_attempt = billing_attempt.refund!(nil, -5)
      refund_bill.amount.should == -5
    end

    it 'should allow a positive number and treat it as negative' do
      subscription = subscriptions(:always_successful_subscription)
      billing_attempt = subscription.payment_method.pay(Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 10))
      refund_bill, refund_attempt = billing_attempt.refund!(nil, 5)
      refund_bill.amount.should == -5
    end

    it 'should let you specify description' do
      subscription = subscriptions(:always_successful_subscription)
      billing_attempt = subscription.payment_method.pay(Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 10))
      refund_bill, refund_attempt = billing_attempt.refund!('custom description')
      refund_bill.description.should == 'custom description'
    end

    it 'should not let you refund an unsuccessful billing attempt' do
      subscription = subscriptions(:zombo_subscription)
      billing_attempt = payment_methods(:always_fails).pay(Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 10))
      lambda { billing_attempt.refund! }.should raise_error(BillingAttempt::InvalidRefund)
    end
  end
end
