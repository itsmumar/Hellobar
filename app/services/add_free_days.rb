class AddFreeDays
  class Error < StandardError
  end

  def initialize(site, days_number)
    @site = site
    @days_number = days_number.to_i.days
  end

  def call
    raise Error, 'Could not add negative days' if days_number < 1
    raise Error, 'Could not add trial days to a free subscription' unless active_subscription&.paid?

    if active_subscription.currently_on_trial?
      update_trial_subscription
    else
      update_paid_subscription
    end
  end

  private

  attr_reader :site, :days_number

  def update_paid_subscription
    update_current_bill
    update_next_bill
  end

  def update_trial_subscription
    update_current_bill
    update_trial_end_date
  end

  def update_trial_end_date
    active_subscription.update(
      trial_end_date: active_subscription.trial_end_date + days_number
    )
  end

  def update_current_bill
    current_bill.update!(
      end_date: current_bill.end_date + days_number
    )
  end

  def update_next_bill
    next_bill.update!(
      bill_at: next_bill.bill_at + days_number,
      start_date: next_bill.start_date + days_number,
      end_date: next_bill.end_date + days_number
    )
  end

  def active_subscription
    @active_subscription ||= site.active_subscription
  end

  def next_bill
    @next_bill ||= active_subscription.bills.pending.last
  end

  def current_bill
    @current_bill ||= active_subscription.bills.paid.last
  end
end
