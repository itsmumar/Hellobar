class ChangeSubscription
  def initialize(site, params, payment_method = nil)
    @site = site
    @old_subscription = site.current_subscription
    @payment_method = payment_method
    @billing_params = params.reverse_merge(schedule: 'monthly')
  end

  def call
    transaction.tap do |bill|
      track_subscription_change(bill.subscription)
    end
  end

  private

  attr_reader :site, :payment_method, :billing_params, :old_subscription

  def transaction
    Subscription.transaction do
      subscription = create_subscription
      bill = create_bill(subscription)
      pay_bill(bill)
    end
  end

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
    Subscription.const_get(billing_params[:plan])
  rescue NameError
    plan_constant = billing_params[:plan].parameterize.underscore.camelize
    Subscription.const_get(plan_constant)
  end

  def track_subscription_change(subscription)
    return unless subscription.persisted?

    props = {
      to_plan: subscription.values[:name],
      to_schedule: subscription.schedule
    }

    if old_subscription
      props[:from_plan] = old_subscription.values[:name]
      props[:from_schedule] = old_subscription.schedule
    end

    BillingLogger.change_subscription(site, props)

    Analytics.track(:site, site.id, :change_sub, props)
  end
end
