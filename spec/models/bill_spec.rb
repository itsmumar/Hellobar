require 'spec_helper'
require 'payment_method_details'

module BillSpecDates
  def june
    Time.zone.parse('2014-06-10')
  end

  def bill_at
    Time.zone.parse('2014-06-11')
  end

  def july
    Time.zone.parse('2014-07-10')
  end

  def aug
    Time.zone.parse('2014-08-10')
  end

  def sep
    Time.zone.parse('2014-09-10')
  end
end

describe Bill do
  include BillSpecDates

  set_fixture_class payment_method_details: PaymentMethodDetails # pluralized class screws up naming convention

  describe 'callbacks' do
    it 'sets the base amount before saving' do
      expect(create(:bill, amount: 10).base_amount).to eq(10)
    end
  end

  it 'should not let create a negative bill' do
    expect { Bill.create(amount: -1) }.to raise_error(Bill::InvalidBillingAmount)
  end

  it 'should not let you change the status once set' do
    bill = create(:pro_bill)
    expect(bill.status).to eq(:pending)
    bill.voided!
    expect(bill.status).to eq(:voided)
    bill = Bill.find(bill.id)
    expect(bill.status).to eq(:voided)
    expect { bill.pending! }.to raise_error(Bill::StatusAlreadySet)
    expect { bill.paid! }.to raise_error(Bill::StatusAlreadySet)
    expect { bill.status = :pending }.to raise_error(Bill::StatusAlreadySet)
  end

  it 'should raise an error if you try to change the status to an invalid value' do
    bill = create(:pro_bill)
    expect { bill.status = 'foo' }.to raise_error(Bill::InvalidStatus)
  end

  it 'should record when the status was set' do
    bill = create(:pro_bill)
    expect(bill.status).to eq(:pending)
    expect(bill.status_set_at).to be_nil
    bill.paid!
    expect(bill.status_set_at).to be_within(2).of(Time.current)
  end

  it 'should take the payment_method grace period into account when grace_period_allowed' do
    now = Time.current
    bill = create(:pro_bill, bill_at: now)
    expect(bill.grace_period_allowed?).to eq(true)
    expect(bill.bill_at).to be_within(5.minutes).of(now)
    expect(bill.due_at).to eq(bill.bill_at)
    payment_method = PaymentMethod.new
    payment_method_details = CyberSourceCreditCard.new
    payment_method.details << payment_method_details
    expect(payment_method_details.grace_period).to be > 5.minutes
    expect(bill.due_at(payment_method)).to eq(bill.bill_at + payment_method_details.grace_period)
    bill.grace_period_allowed = false
    expect(bill.due_at(payment_method)).to eq(bill.bill_at)
  end

  it 'should return the payment details of the successful billing attempt' do
    bill = create(:pro_bill, :paid)
    expect(bill.paid_with_payment_method_detail).to be_a AlwaysSuccessfulPaymentMethodDetails
  end

  describe '#during_trial_subscription?' do
    it 'should not be on trial subscription' do
      bill = create(:pro_bill, :paid)
      expect(bill.during_trial_subscription?).to be_falsey
    end

    it 'should be on trial subscription' do
      bill = create(:pro_bill, :paid)
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      expect(bill.during_trial_subscription?).to be_truthy
    end
  end

  describe Bill::Recurring do
    it 'should create the next bill once paid' do
      subscription = create(:subscription, :pro)
      Bill.destroy_all
      expect(subscription.bills(true).length).to eq(0)
      expect(subscription).to be_monthly
      bill = Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 1)
      expect(subscription.bills(true).length).to eq(1)
      bill.paid!
      expect(subscription.bills(true).length).to eq(2)
      bill1 = subscription.bills[0]
      expect(bill1).to be_paid
      expect(bill1.start_date).to eq(june)
      expect(bill1.end_date).to eq(july)
      bill2 = subscription.bills[1]
      expect(bill2).to be_pending
      expect(bill2.start_date).to eq(july)
      expect(bill2.bill_at).to eq(july)
      expect(bill2.end_date).to eq(aug)
    end

    it 'should return the correct date for next_month' do
      expect(Bill::Recurring.next_month(Time.zone.parse('2014-12-30')).strftime('%Y-%m-%d')).to eq('2015-01-30')
      expect(Bill::Recurring.next_month(Time.zone.parse('2015-01-30')).strftime('%Y-%m-%d')).to eq('2015-02-28')
      expect(Bill::Recurring.next_year(Time.zone.parse('2014-12-30')).strftime('%Y-%m-%d')).to eq('2015-12-30')
      expect(Bill::Recurring.next_year(Time.zone.parse('2016-02-29')).strftime('%Y-%m-%d')).to eq('2017-02-28')
    end

    it 'should not be affected by a refund' do
      subscription = create(:subscription, :pro)
      Bill.destroy_all
      expect(subscription.bills(true).length).to eq(0)
      expect(subscription).to be_monthly
      bill = Bill::Recurring.create!(subscription: subscription, start_date: june, end_date: july, bill_at: bill_at, amount: 1)
      expect(subscription.bills(true).length).to eq(1)
      bill.attempt_billing!
      RefundBill.new(bill).call
      expect(subscription.bills(true).length).to eq(3)
      initial_bill = subscription.bills[0]
      recurring_bill = subscription.bills[1]
      subscription.bills[2]
      recurring_bill.paid!
      expect(subscription.bills(true).length).to eq(4)
      recurring_bill2 = subscription.bills[3]
      expect(initial_bill).to be_paid
      expect(initial_bill.start_date).to eq(june)
      expect(initial_bill.end_date).to eq(july)
      expect(recurring_bill).to be_paid
      expect(recurring_bill.start_date).to eq(july)
      expect(recurring_bill.bill_at).to eq(initial_bill.end_date)
      expect(recurring_bill.end_date).to eq(aug)
      # Next recurring bill should be unaffected by refund
      expect(recurring_bill2).to be_pending
      expect(recurring_bill2.start_date).to eq(aug)
      expect(recurring_bill2.bill_at).to eq(recurring_bill.end_date)
      expect(recurring_bill2.end_date).to eq(recurring_bill2.start_date + 1.month)
    end
  end

  describe 'attempt_billing!' do
    it 'calls set_final_amount' do
      bill = create(:pro_bill)
      expect(bill).to receive(:set_final_amount!)
      bill.attempt_billing!
    end

    it 'should call payment_method.pay if the bill.amount > 0' do
      bill = create(:bill)
      bill.subscription.payment_method = create(:payment_method, :success)
      expect_any_instance_of(PaymentMethod).to receive(:pay).with(bill)
      bill.attempt_billing!
    end

    it 'should mark it as paid if the bill amount is 0' do
      bill = create(:free_bill)
      expect_any_instance_of(PaymentMethod).not_to receive(:pay).with(bill)
      bill.attempt_billing!
    end
  end

  describe 'set_final_amount' do
    let!(:bill) { create(:pro_bill) }
    let!(:user) { create(:user) }
    let!(:refs) do
      (1..3).map do
        create(:referral, sender: user, site: bill.site, state: 'installed', available_to_sender: true)
      end
    end

    before do
      bill.site.owners << user
    end

    it "sets the final amount to 0 if there's a discount for 15.0" do
      allow(bill).to receive(:calculate_discount).and_return(15.0)
      bill.attempt_billing!
      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's a discount for 2.0" do
      create(:referral_coupon)
      allow(bill).to receive(:calculate_discount).and_return(2.0)

      expect {
        bill.attempt_billing!
      }.to change { user.sent_referrals.redeemable_for_site(bill.site).count }.by(-1)

      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's no discount" do
      create(:referral_coupon)
      allow(bill).to receive(:calculate_discount).and_return(0.0)

      expect {
        bill.attempt_billing!
      }.to change { user.sent_referrals.redeemable_for_site(bill.site).count }.by(-1)

      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
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
      bills =
        Array.new(350) do
          bill = create(:pro_bill, status: :paid)
          bill.site.users << user
          user.reload
          bill.subscription.payment_method.update(user: user)
          bill.update(discount: bill.calculate_discount)
          bill
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
      expect(create(:pro_bill, :paid).problem_with_payment?).to eq(false)
    end

    it 'should return false if voided' do
      expect(create(:bill, :voided).problem_with_payment?).to eq(false)
    end

    it 'should return false if amount is zero' do
      bill = create(:free_bill)
      expect(bill.should_bill?).to eq(true)
      expect(bill.problem_with_payment?).to eq(false)
    end

    it 'should return true if pending and past due' do
      bill = create(:past_due_bill)
      expect(bill.should_bill?).to eq(true)
      expect(bill.past_due?).to eq(true)
      expect(bill.problem_with_payment?).to eq(true)
    end

    it "should return false if due, but haven't tried billing yet" do
      bill = create(:past_due_bill)
      pm = create(:payment_method, :success)
      # Get around destroying read-only records
      BillingAttempt.connection.execute("DELETE FROM #{ BillingAttempt.table_name }")
      expect(bill.should_bill?).to eq(true)
      expect(bill.past_due?).to eq(true)
      expect(bill.problem_with_payment?(pm)).to eq(false)
    end

    it 'should return true if past due and there is no payment method' do
      bill = create(:past_due_bill)
      bill.billing_attempts.delete_all
      expect(bill.problem_with_payment?).to eq(true)
    end
  end
end

describe Subscription do
  it 'should return all pending bills' do
    subscription = create(:subscription, :with_bills)
    expect(subscription.bills.count).to eq(2)
    expect(subscription.pending_bills(true).count).to eq(2)
    subscription.bills.first.voided!
    expect(subscription.pending_bills(true).count).to eq(1)
  end

  it 'should return all paid bills' do
    subscription = create(:subscription, :with_bills)
    expect(subscription.bills.count).to eq(2)
    expect(subscription.paid_bills(true).count).to eq(0)
    subscription.bills.first.paid!
    expect(subscription.paid_bills(true).length).to eq(1)
  end

  it 'should return all bills active for time period' do
    now = Time.current
    subscription = create(:subscription, :with_bills)
    Bill.delete_all
    expect(subscription.active_bills(true).length).to eq(0)
    # Add a bill after
    Bill.create!(subscription: subscription, start_date: now + 15.days, end_date: now + 45.days, amount: 1)
    expect(subscription.active_bills(true).length).to eq(0)
    # Add a bill before
    Bill.create!(subscription: subscription, start_date: now - 45.days, end_date: now - 15.days, amount: 1)
    expect(subscription.active_bills(true).length).to eq(0)
    # Add a bill during time, but voided
    Bill.create!(subscription: subscription, start_date: now, end_date: now + 30.days, status: :voided, amount: 1)
    expect(subscription.active_bills(true).length).to eq(0)
    # Add an active bill
    Bill.create!(subscription: subscription, start_date: now, end_date: now + 30.days, amount: 1)
    expect(subscription.active_bills(true).length).to eq(1)
  end
end

describe PaymentMethod do
  include BillSpecDates

  describe 'pay' do
    it 'should attempt to charge the bill with the payment method' do
      payment_method = create(:payment_method, :success)
      bill = create(:bill)
      expect_any_instance_of(AlwaysSuccessfulPaymentMethodDetails).to receive(:charge).with(bill.amount)
      payment_method.pay(bill)
    end

    it 'should mark the bill as paid if successul' do
      bill = create(:bill)
      expect(create(:payment_method, :success).pay(bill)).to be_success
      expect(bill).to be_paid
    end

    it 'should not mark the bill as paid if failed' do
      bill = create(:bill)
      payment_method = create(:payment_method, :fails)
      expect(payment_method.pay(bill)).not_to be_success
      expect(bill).not_to be_paid
    end

    it 'should create a BillingAttempt either way' do
      billing_attempt = create(:payment_method, :success).pay(create(:bill))
      expect(billing_attempt).not_to be_nil
      expect(billing_attempt).to be_persisted
      expect(billing_attempt.payment_method_details).not_to be_nil
      expect(billing_attempt.bill).not_to be_nil
      expect(billing_attempt.response).not_to be_nil
      expect(billing_attempt).to be_success
      # failure
      billing_attempt = create(:payment_method, :fails).pay(create(:bill))
      expect(billing_attempt).not_to be_nil
      expect(billing_attempt).to be_persisted
      expect(billing_attempt.payment_method_details).not_to be_nil
      expect(billing_attempt.bill).not_to be_nil
      expect(billing_attempt.response).not_to be_nil
      expect(billing_attempt).not_to be_success
    end

    it 'should raise an error if no payment_method_details' do
      expect { PaymentMethod.new.pay(create(:bill)) }.to raise_error(PaymentMethod::MissingPaymentDetails)
    end
  end
end
