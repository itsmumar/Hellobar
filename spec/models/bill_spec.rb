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

  describe '.without_refunds' do
    let!(:bill) { create :bill }
    let!(:refunded_bill) { create :bill, :paid }

    before { stub_cyber_source :refund }
    before { RefundBill.new(refunded_bill).call }

    it 'returns bills which have not been refunded' do
      expect(Bill.without_refunds).to match_array [bill]
    end
  end

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
    let!(:bill) { create(:pro_bill, bill_at: 15.days.ago) }
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
      PayBill.new(bill).call
      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's a discount for 2.0" do
      create(:referral_coupon)
      allow(bill).to receive(:calculate_discount).and_return(2.0)

      expect {
        PayBill.new(bill).call
      }.to change { user.sent_referrals.redeemable_for_site(bill.site).count }.by(-1)

      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
    end

    it "sets the final amount to 0 and uses up one available referral if there's no discount" do
      create(:referral_coupon)
      allow(bill).to receive(:calculate_discount).and_return(0.0)

      expect {
        PayBill.new(bill).call
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
    context 'when paid' do
      let(:bill) { create :pro_bill, :paid }

      specify { expect(bill).not_to be_problem_with_payment }
    end

    context 'when void' do
      let(:bill) { create :pro_bill, :void }

      specify { expect(bill).not_to be_problem_with_payment }
    end

    context 'when amount is zero' do
      let(:bill) { create :free_bill }

      specify { expect(bill).not_to be_problem_with_payment }
      specify { expect(bill).to be_should_bill }
    end

    context 'when pending and past due' do
      let(:bill) { create :past_due_bill }

      specify { expect(bill).to be_problem_with_payment }
      specify { expect(bill).to be_should_bill }
      specify { expect(bill).to be_past_due }
    end

    context 'when past due but have not tried billing yet' do
      let(:bill) { create :past_due_bill }
      let(:payment_method) { create :payment_method }
      before { bill.billing_attempts.delete_all }

      specify { expect(bill).not_to be_problem_with_payment(payment_method) }
      specify { expect(bill).to be_should_bill }
      specify { expect(bill).to be_past_due }
    end

    context 'when past due and there is no payment method' do
      let(:bill) { create :pro_bill }
      before { bill.billing_attempts.delete_all }

      specify { expect(bill).to be_problem_with_payment }
      specify { expect(bill).to be_past_due }
    end
  end
end

describe Subscription do
  describe '#active_bills' do
    let!(:subscription) { create(:subscription, :with_bills) }

    before { Bill.delete_all }

    it 'returns all bills active for time period', :freeze do
      expect(subscription.active_bills(true)).to be_empty

      # Add a bill after
      create(:bill, subscription: subscription, start_date: 15.days.from_now, end_date: 45.days.from_now, amount: 1)
      expect(subscription.active_bills(true)).to be_empty

      # Add a bill before
      create(:bill, subscription: subscription, start_date: 45.days.ago, end_date: 15.days.ago, amount: 1)
      expect(subscription.active_bills(true)).to be_empty

      # Add a bill during time, but voided
      create(:bill, subscription: subscription, start_date: Time.current, end_date: 30.days.from_now, status: :voided, amount: 1)
      expect(subscription.active_bills(true)).to be_empty

      # Add an active bill
      bill = create(:bill, subscription: subscription, start_date: Time.current, end_date: 30.days.from_now, amount: 1)
      expect(subscription.active_bills(true)).to match_array [bill]
    end
  end
end
