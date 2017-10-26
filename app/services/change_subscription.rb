class ChangeSubscription
  def initialize(site, params, credit_card = nil)
    @site = site
    @old_subscription = site.current_subscription
    @credit_card = credit_card
    @billing_params = params.reverse_merge(schedule: 'monthly')
  end

  def call
    change_or_update_subscription.tap do
      regenerate_script
    end
  end

  private

  attr_reader :site, :credit_card, :billing_params, :old_subscription

  def change_or_update_subscription
    if same_subscription?
      update_credit_card
    else
      change_subscription
    end
  end

  def regenerate_script
    site.script.generate
  end

  def cancel_subscription_if_it_is_free
    return if !old_subscription || old_subscription.paid?
    old_subscription.bills.free.each(&:voided!)
  end

  def same_subscription?
    old_subscription.is_a?(subscription_class) &&
      billing_params[:schedule] == old_subscription.schedule
  end

  def update_credit_card
    site.current_subscription.update! credit_card: credit_card
    try_to_pay_failed_bill
    old_subscription.bills.last
  end

  def try_to_pay_failed_bill
    return unless (last_failed_bill = site.current_subscription.bills.failed.last)
    PayBill.new(last_failed_bill).call
  end

  def change_subscription
    cancel_subscription_if_it_is_free
    create_subscription_and_pay_bill
  end

  def create_subscription_and_pay_bill
    Subscription.transaction do
      void_pending_bills!
      subscription = create_subscription
      track_subscription_change(subscription)
      create_and_pay_bill_if_necessary(subscription)
    end
  end

  def create_and_pay_bill_if_necessary(subscription)
    return if subscription_class == Subscription::Free
    bill = create_bill(subscription)
    pay_bill(bill)
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
    raise_record_invalid_if_failed(bill)
    bill
  end

  def raise_record_invalid_if_failed(bill)
    return unless bill.failed?
    bill.errors.add :base,
      "There was a problem while charging your credit card ending in #{ credit_card.last_digits }." \
      ' You can fix this by adding another credit card'
    raise ActiveRecord::RecordInvalid, bill
  end

  def create_bill(subscription)
    CalculateBill.new(subscription, bills: site.bills).call.tap(&:save!)
  end

  def void_pending_bills!
    site.bills.pending.each(&:voided!)
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
