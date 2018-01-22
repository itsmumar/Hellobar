class UsePromotionalCode
  def initialize site, promotional_code
    @site = site
    @promotional_code = promotional_code
  end

  def call
    return unless valid_promotional_code?

    add_trial_subscription
  end

  private

  attr_reader :site, :promotional_code

  def valid_promotional_code?
    coupon
  end

  def coupon
    @coupon ||= Coupon.find_by label: promotional_code
  end

  def add_trial_subscription
    AddTrialSubscription.new(site, subscription_params).call
  end

  def subscription_params
    {
      subscription: 'pro',
      trial_period: 60
    }
  end
end
