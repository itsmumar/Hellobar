class AddTrialSubscription
  def initialize(site, params)
    @site = site
    @subscription = params[:subscription]
    @duration = to_duration params[:trial_period]
  end

  def call
    raise 'wrong trial period' if duration > 90.days || duration < 1.day
    void_active_free_bill
    create_trial_subscription
  end

  private

  attr_reader :site, :subscription, :duration

  def void_active_free_bill
    return unless site.active_paid_bill
    site.active_paid_bill.voided! if site.active_paid_bill.amount.zero?
  end

  def create_trial_subscription
    Subscription.transaction do
      subscription = subscription_class.create!(site: site, trial_end_date: duration.from_now)
      create_bill subscription
    end
  end

  def create_bill(subscription)
    Bill::Recurring.create!(subscription: subscription) do |bill|
      bill.status = :paid
      bill.amount = 0
      bill.grace_period_allowed = false
      bill.bill_at = Time.current
      bill.start_date = Time.current
      bill.end_date = duration.from_now
    end
  end

  def subscription_class
    Subscription.const_get(subscription.camelize)
  end

  def to_duration(duration_or_days)
    if duration_or_days.is_a? ActiveSupport::Duration
      duration_or_days
    else
      duration_or_days.to_i.days
    end
  end
end
