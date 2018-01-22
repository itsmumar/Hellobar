class UsePromotionalCode
  def initialize site, user, promotional_code
    @site = site
    @user = user
    @promotional_code = promotional_code
  end

  def call
    return unless valid_promotional_code?

    CouponUse.transaction do
      bill = add_trial_subscription
      CouponUse.create!(bill: bill, coupon: coupon)
    end
  end

  private

  attr_reader :site, :user, :promotional_code

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
