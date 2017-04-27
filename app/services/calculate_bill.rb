class CalculateBill
  include BillingAuditTrail

  attr_reader :site, :subscription, :actually_change, :trial_period

  def initialize(site, subscription, actually_change, trial_period)
    @site = site
    @subscription = subscription
    @actually_change = actually_change
    @trial_period = trial_period
  end

  def call
    now = Time.current
    # First we need to void any pending recurring bills
    # and keep any active paid bills
    active_paid_bills = []
    site.bills(true).each do |bill|
      if bill.is_a?(Bill::Recurring)
        if bill.pending?
          bill.void! if actually_change
        elsif bill.paid?
          active_paid_bills << bill if bill.active_during(now)
        end
      end
    end
    if actually_change
      audit << "Changing subscription to #{ subscription.inspect }"
    end
    bill = Bill::Recurring.new(subscription: subscription)
    if active_paid_bills.empty?
      # Gotta pay full amount now
      bill.amount = subscription.amount
      bill.grace_period_allowed = false
      bill.bill_at = now
      if actually_change
        audit << "No active paid bills, charging full amount now: #{ bill.inspect }"
      end
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
        if actually_change
          audit << "now: #{ now }, start_date: #{ active_paid_bills.last.start_date }, end_date: #{ active_paid_bills.last.end_date }, total_days_of_last_subscription: #{ total_days_of_last_subcription.inspect }, num_days_used: #{ num_days_used }, percentage_unused: #{ percentage_unused }"
        end

        unused_paid_amount = last_subscription.amount * percentage_unused
        # Subtract the unused paid amount from the price and round it
        bill.amount = (subscription.amount - unused_paid_amount).to_i
        if actually_change
          audit << "Upgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, prorating amount now: #{ bill.inspect }"
        end
      else
        # We are downgrading or staying the same, so just set the bill to start
        # after this bill ends, but make it the full amount
        bill.bill_at = active_paid_bills.last.end_date
        bill.amount = subscription.amount
        bill.grace_period_allowed = true
        if actually_change
          audit << "Downgrade from active bill: #{ active_paid_bills.last.inspect } changing from subscription #{ active_paid_bills.last.subscription.inspect }, charging full amount later: #{ bill.inspect }"
        end
      end
    end

    bill.start_date = bill.bill_at - 1.hour
    bill.end_date = bill.renewal_date

    if trial_period
      bill.amount = 0
      bill.end_date = Time.current + trial_period
    end

    bill
  end
end
