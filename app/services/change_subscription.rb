class ChangeSubscription
  def initialize(site, params, credit_card = nil)
    @site = site
    @old_subscription = site.current_subscription
    @credit_card = credit_card
    @billing_params = params.reverse_merge(schedule: 'monthly')
  end

  def call
    transaction.tap do |bill|
      track_subscription_change(bill.subscription)
    end
  end

  private

  attr_reader :site, :credit_card, :billing_params, :old_subscription

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
      credit_card: credit_card,
      schedule: billing_params[:schedule]
    )
  end

  def pay_bill(bill)
    PayBill.new(bill).call if bill.due_at(credit_card) <= Time.current
    bill
  end

  def create_bill(subscription)
    CalculateBill.new(subscription, bills: site.bills.recurring).call.tap(&:save!)
  end

  def subscription_class
    Subscription.const_get(billing_params[:subscription].camelize)
  end

  def track_subscription_change(subscription)
    return unless subscription.persisted?

    props = {
      to_subscription: subscription.values[:name],
      to_schedule: subscription.schedule
    }

    if old_subscription
      props[:from_subscription] = old_subscription.values[:name]
      props[:from_schedule] = old_subscription.schedule
    end

    BillingLogger.change_subscription(site, props)

    Analytics.track(:site, site.id, :change_sub, props)
    TrackEvent.new(:changed_subscription, site: site, user: site.owners.first).call
  end
end
