class CalculateBill
  include BillingAuditTrail

  # @param [Bill::ActiveRecord_Relation] bills
  # @param [Subscription] subscription
  # @param [Boolean] trial_period
  def initialize(subscription, bills:, trial_period: nil)
    @subscription = subscription
    @bills = bills
    @trial_period = trial_period
  end

  def call
    void_pending_bills!

    audit << "Changing subscription to #{ subscription.inspect }"

    if active_paid_bills.empty?
      make_bill_to_full_amount
    elsif upgrading?
      make_bill_for_upgrading
    else
      make_bill_for_downgrading
    end
  end

  private

  attr_reader :bills, :subscription, :trial_period

  def void_pending_bills!
    bills.pending.each(&:voided!)
  end

  def active_paid_bills
    @active_paid_bills ||= bills.paid.without_refunds.order('id').select { |bill| bill.active_during(Time.current) }
  end

  def last_subscription
    @last_subscription ||= active_paid_bills.last.subscription
  end

  def make_bill_to_full_amount
    make_bill do |bill|
      audit << "No active paid bills, charging full amount now: #{ bill.inspect }"
    end
  end

  def make_bill_for_upgrading
    make_bill do |bill|
      bill.amount = calculate_reduced_amount
      audit << "Upgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, prorating amount now: #{ bill.inspect }"
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
      bill.start_date = bill.bill_at - 1.hour
      audit << "Downgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, charging full amount later: #{ bill.inspect }"
    end
  end

  # Subtract the unused paid amount from the price and round it
  def calculate_reduced_amount
    num_days_used = (Time.current - active_paid_bills.last.start_date) / 1.day
    total_days_of_last_subcription = (active_paid_bills.last.end_date - active_paid_bills.last.start_date) / 1.day
    percentage_unused = 1.0 - (num_days_used.to_f / total_days_of_last_subcription)
    audit << "now: #{ Time.current }, start_date: #{ active_paid_bills.last.start_date }, end_date: #{ active_paid_bills.last.end_date }, total_days_of_last_subscription: #{ total_days_of_last_subcription.inspect }, num_days_used: #{ num_days_used }, percentage_unused: #{ percentage_unused }"

    unused_paid_amount = last_subscription.amount * percentage_unused
    (subscription.amount - unused_paid_amount).to_i
  end

  def make_bill(&block)
    Bill::Recurring.new(subscription: subscription) do |bill|
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = Time.current
      bill.start_date = 1.hour.ago

      block.call bill if block_given?

      bill.end_date = bill.start_date + subscription.period
      use_trial_period bill
    end
  end

  def use_trial_period(bill)
    return unless trial_period

    bill.amount = 0
    bill.end_date = Time.current + trial_period
  end

  def upgrading?
    Subscription::Comparison.new(active_paid_bills.last.subscription, subscription).upgrade?
  end
end
