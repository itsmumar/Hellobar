class AddFreeDaysOrTrialSubscription
  def initialize(site, period, subscription: 'pro')
    @site = site
    @subscription = site&.active_subscription
    @subscription_type = subscription
    @period = period
  end

  def call
    if subscription&.paid?
      add_free_days
    else
      add_trial_subscription
    end
  end

  private

  attr_reader :site, :subscription, :subscription_type, :period

  def add_free_days
    AddFreeDays.new(site, period).call
  end

  def add_trial_subscription
    AddTrialSubscription.new(
      site,
      subscription: subscription_type,
      trial_period: period
    ).call
  end
end
