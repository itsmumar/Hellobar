class AddFreeDays
  class Error < StandardError
  end

  def initialize(site, duration_or_days)
    @site = site
    @duration = to_duration duration_or_days
  end

  def call
    raise Error, 'Invalid number of days' if duration < 1
    raise Error, 'Could not add trial days to a free subscription' unless active_subscription&.paid?

    if active_subscription.currently_on_trial?
      update_trial_subscription
    else
      update_paid_subscription
    end

    current_bill
  end

  private

  attr_reader :site, :duration

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
      trial_end_date: active_subscription.trial_end_date + duration
    )
  end

  def update_current_bill
    current_bill.update!(
      end_date: current_bill.end_date + duration
    )
  end

  def update_next_bill
    next_bill.update!(
      bill_at: next_bill.bill_at + duration,
      start_date: next_bill.start_date + duration,
      end_date: next_bill.end_date + duration
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

  def to_duration(duration_or_days)
    if duration_or_days.is_a? ActiveSupport::Duration
      duration_or_days
    else
      duration_or_days.to_i.days
    end
  end
end
