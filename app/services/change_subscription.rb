class ChangeSubscription
  def initialize(site, params, credit_card = nil)
    @site = site
    @old_subscription = site.current_subscription
    @credit_card = credit_card
    @billing_params = params.reverse_merge(schedule: 'monthly')
  end

  def call
    if same_subscription?
      update_credit_card
    else
      change_subscription
    end
  end

  private

  attr_reader :site, :credit_card, :billing_params, :old_subscription

  def same_subscription?
    old_subscription.is_a?(subscription_class) &&
      billing_params[:schedule] == old_subscription.schedule
  end

  def update_credit_card
    old_subscription.update credit_card: credit_card
    try_to_pay_problem_bill
    old_subscription.bills.last
  end

  def try_to_pay_problem_bill
    return unless (last_problem_bill = old_subscription.bills.problem.last)
    PayBill.new(last_problem_bill).call
  end

  def change_subscription
    create_subscription_and_pay_bill.tap do |bill|
      track_subscription_change(bill.subscription)
    end
  end

  def create_subscription_and_pay_bill
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
    raise_record_invalid_if_problem(bill)
    bill
  end

  def raise_record_invalid_if_problem(bill)
    return unless bill.problem?
    bill.errors.add :base,
      "There was a problem while charging your credit card ending in #{ credit_card.last_digits }." \
      ' You can fix this by adding another credit card'
    raise ActiveRecord::RecordInvalid, bill
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
