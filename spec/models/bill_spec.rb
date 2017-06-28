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
        Array.new(35) do
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
      pm = create(:payment_method)
      BillingAttempt.delete_all
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
