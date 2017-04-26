class CalculateBill
  include BillingAuditTrail

  # @param [Site] site
  # @param [Subscription] subscription
  # @param [Boolean] trial_period
  def initialize(site, subscription, trial_period)
    @site = site
    @subscription = subscription
    @trial_period = trial_period
  end

  def call
    now = Time.now
    # First we need to void any pending recurring bills
    # and keep any active paid bills
    active_paid_bills = []
    site.bills.recurring.each do |bill|
      if bill.pending?
        bill.void!
      elsif bill.paid?
        active_paid_bills << bill if bill.active_during(now)
      end
    end
    audit << "Changing subscription to #{ subscription.inspect }"

    bill = Bill::Recurring.new(subscription: subscription)
    if active_paid_bills.empty?
      # Gotta pay full amount now
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = now
      audit << "No active paid bills, charging full amount now: #{ bill.inspect }"
    else
      last_subscription = active_paid_bills.last.subscription

      if Subscription::Comparison.new(last_subscription, subscription).upgrade?
        # We are upgrading, gotta pay now, but we prorate it

        bill.bill_at = now
        bill.grace_period_allowed = false
        # Figure out percentage of their subscription they've used
        # rounded to the day
        num_days_used = (now - active_paid_bills.last.start_date) / 1.day
        total_days_of_last_subcription = (active_paid_bills.last.end_date - active_paid_bills.last.start_date) / 1.day
        percentage_used = num_days_used.to_f / total_days_of_last_subcription
        percentage_unused = 1.0 - percentage_used
        audit << "now: #{ now }, start_date: #{ active_paid_bills.last.start_date }, end_date: #{ active_paid_bills.last.end_date }, total_days_of_last_subscription: #{ total_days_of_last_subcription.inspect }, num_days_used: #{ num_days_used }, percentage_unused: #{ percentage_unused }"

        unused_paid_amount = last_subscription.amount * percentage_unused
        # Subtract the unused paid amount from the price and round it
        bill.amount = (subscription.amount - unused_paid_amount).to_i
        audit << "Upgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, prorating amount now: #{ bill.inspect }"
      else
        # We are downgrading or staying the same, so just set the bill to start
        # after this bill ends, but make it the full amount
        bill.bill_at = active_paid_bills.last.end_date
        bill.amount = subscription.amount
        bill.grace_period_allowed = true
        audit << "Downgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, charging full amount later: #{ bill.inspect }"
      end
    end

    bill.start_date = bill.bill_at - 1.hour
    bill.end_date = bill.renewal_date

    if trial_period
      bill.amount = 0
      bill.end_date = Time.now + trial_period
    end

    bill
  end

  private

  attr_reader :site, :subscription, :trial_period
end
