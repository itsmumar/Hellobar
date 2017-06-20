class UpgradeSubscription
  def initialize(site, payment_method, params)
    @site = site
    @payment_method = payment_method
    @billing_params = params.fetch(:billing)
  end

  def call
    subscription = create_subscription
    bill = create_bill(subscription)
    pay_bill(bill)
  end

  private

  attr_reader :site, :payment_method, :billing_params

  def create_subscription
    subscription_class.create!(
      site: site,
      payment_method: payment_method,
      schedule: billing_params[:schedule]
    )
  end

  def pay_bill(bill)
    PayBill.new(bill).call
  end

  def create_bill(subscription)
    CalculateBill.new(subscription, bills: site.bills.recurring, trial_period: trial_period).call.tap(&:save!)
  end

  def trial_period
    billing_params[:trial_period].presence&.to_i&.days
  end

  def subscription_class
    plan_constant = billing_params[:plan].parameterize.underscore.camelize
    Subscription.const_get(plan_constant)
  end
end
