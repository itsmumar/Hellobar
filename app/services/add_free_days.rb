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

    update_current_bill
    create_or_update_next_bill
    update_trial_end_date if active_subscription.currently_on_trial?

    track_event
    current_bill
  end

  private

  attr_reader :site, :duration

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

  def create_or_update_next_bill
    next_bill ? update_next_bill : create_next_bill
  end

  def create_next_bill
    CreateBillForNextPeriod.new(current_bill).call
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

  def track_event
    bill = current_bill

    TrackEvent.new(
      :granted_free_days,
      subscription: bill.subscription,
      user: bill.subscription&.credit_card&.user || bill.site.owners.first,
      free_days: duration / 1.day
    ).call
  end
end
