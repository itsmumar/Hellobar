class AddTrialSubscription
  def initialize(site, params)
    @site = site
    @subscription = params[:subscription]
    @period = to_period params[:trial_period]
  end

  def call
    raise 'wrong trial period' unless period.in?(1..90)
    void_active_free_bill
    create_trial_subscription
  end

  private

  attr_reader :site, :subscription, :period

  def void_active_free_bill
    return unless site.active_paid_bill
    site.active_paid_bill.voided! if site.active_paid_bill.amount.zero?
  end

  def create_trial_subscription
    Subscription.transaction do
      subscription = subscription_class.create!(site: site, trial_end_date: period.days.from_now)
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
      bill.end_date = period.days.from_now
    end
  end

  def subscription_class
    Subscription.const_get(subscription.camelize)
  end

  def to_period(duration_or_period)
    if duration_or_period.is_a? ActiveSupport::Duration
      duration = duration_or_period.from_now - Time.current
      (duration / 1.day).round
    else
      duration_or_period.to_i
    end
  end
end
