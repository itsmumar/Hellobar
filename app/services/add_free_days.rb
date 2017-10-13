class AddFreeDays
  class Error < StandardError
  end

  def initialize(site, days_number)
    @site = site
    @period = to_period days_number
  end

  def call
    raise Error, 'Could not add negative days' if period < 1
    raise Error, 'Could not add trial days to a free subscription' unless active_subscription&.paid?

    if active_subscription.currently_on_trial?
      update_trial_subscription
    else
      update_paid_subscription
    end

    current_bill
  end

  private

  attr_reader :site, :period

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
      trial_end_date: active_subscription.trial_end_date + period
    )
  end

  def update_current_bill
    current_bill.update!(
      end_date: current_bill.end_date + period
    )
  end

  def update_next_bill
    next_bill.update!(
      bill_at: next_bill.bill_at + period,
      start_date: next_bill.start_date + period,
      end_date: next_bill.end_date + period
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

  def to_period(duration_or_period)
    if duration_or_period.is_a? ActiveSupport::Duration
      duration_or_period
    else
      duration_or_period.to_i.days
    end
  end
end
