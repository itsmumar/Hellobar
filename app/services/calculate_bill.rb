class CalculateBill
  # @param [Bill::ActiveRecord_Relation] bills
  # @param [Subscription] subscription
  def initialize(subscription, bills:)
    @subscription = subscription
    @bills = bills
  end

  def call
    if active_paid_bills.empty?
      make_bill_to_full_amount
    elsif upgrading?
      make_bill_for_upgrading
    else
      make_bill_for_downgrading
    end
  end

  private

  attr_reader :bills, :subscription

  def active_paid_bills
    @active_paid_bills ||= bills.paid.active.without_refunds
  end

  def last_subscription
    @last_subscription ||= active_paid_bills.last.subscription
  end

  def make_bill_to_full_amount
    make_bill
  end

  def make_bill_for_upgrading
    make_bill do |bill|
      bill.amount = calculate_reduced_amount
    end
  end

  # We are downgrading or staying the same,
  # so just set the bill to start after this bill ends,
  # but make it the full amount
  def make_bill_for_downgrading
    make_bill do |bill|
      bill.amount = subscription.amount
      bill.grace_period_allowed = true
      bill.bill_at = active_paid_bills.last.end_date
      bill.start_date = bill.bill_at
    end
  end

  # Subtract the unused paid amount from the price and round it
  def calculate_reduced_amount
    num_days_used = (Time.current - active_paid_bills.last.start_date) / 1.day
    last_paid_bill = active_paid_bills.last
    total_days_of_last_subcription = (last_paid_bill.end_date - last_paid_bill.start_date) / 1.day
    percentage_unused = 1.0 - (num_days_used.to_f / total_days_of_last_subcription)

    unused_paid_amount = last_subscription.amount * percentage_unused
    (subscription.amount - unused_paid_amount).to_i
  end

  def make_bill
    Bill::Recurring.new(subscription: subscription) do |bill|
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = Time.current

      yield bill if block_given?
      bill.start_date = bill.bill_at
      bill.end_date = bill.start_date + subscription.period
    end
  end

  def upgrading?
    Subscription::Comparison.new(active_paid_bills.last.subscription, subscription).upgrade?
  end
end
