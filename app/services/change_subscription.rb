class ChangeSubscription
  ONE_DOLLAR_PRO_SPECIAL_END_DATE = Date.parse('2019-01-10')

  def initialize(site, params, credit_card = nil)
    @site = site
    @old_subscription = site.current_subscription
    @credit_card = credit_card
    @billing_params = params.reverse_merge(schedule: 'monthly')
  end

  def call
    return downgrade_site_to_free if downgrading_to_free?

    change_or_update_subscription.tap do
      regenerate_script
    end
  end

  def same_subscription?
    old_subscription.is_a?(subscription_class) &&
      billing_params[:schedule] == old_subscription.schedule
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
    old_subscription.bills.free.each(&:void!)
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
    override_pro_special_monthly_price(bill)
    pay_bill(bill)
  end

  def override_pro_special_monthly_price(bill)
    pro_special = subscription_class == Subscription::ProSpecial

    return if Date.current > ONE_DOLLAR_PRO_SPECIAL_END_DATE
    return unless pro_special && bill.subscription.monthly?

    bill.amount = 1
    bill.base_amount = nil
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
    reset_current_overage_count(bill)
    bill
  end

  def raise_record_invalid_if_failed(bill)
    return unless bill.failed?
    bill.errors.add :base,
      "There was a problem while charging your credit card ending in #{ credit_card.last_digits }." \
      ' You can fix this by adding another credit card'
    raise ActiveRecord::RecordInvalid, bill
  end

  def reset_current_overage_count(bill)
    # When a user upgrades, we need to reduce their Site#overage_count to suit the higher limits
    # of the new subscription. We don't need to worry about doing this for downgrades because
    # the overage_count will be going up and so will be handled by the HandleOverageSite job
    # when it runs tomorrow
    return if bill.failed?
    site.update_attribute('overage_count', 0) # reset to zero and now let's recalculate
    ResetCurrentOverageJob.perform_later(site)
  end

  def create_bill(subscription)
    CalculateBill.new(subscription, bills: site.bills).call.tap(&:save!)
  end

  def void_pending_bills!
    site.bills.pending.each(&:void!)
  end

  def subscription_class
    Subscription.const_get(billing_params[:subscription].to_s.camelize)
  end

  def track_subscription_change(subscription)
    return unless subscription&.persisted?

    props = {
      to_subscription: subscription.values[:name],
      to_schedule: subscription.schedule
    }

    if old_subscription
      props[:from_subscription] = old_subscription.values[:name]
      props[:from_schedule] = old_subscription.schedule
    end

    BillingLogger.change_subscription(site, props)

    TrackSubscriptionChange.new(credit_card&.user || site.owners.first, old_subscription, subscription).call
  end

  def downgrading_to_free?
    subscription_class == Subscription::Free && old_subscription
  end

  def downgrade_site_to_free
    subscription = DowngradeSiteToFree.new(site).call
    track_subscription_change(subscription)

    # since the service has to return a bill
    # let's just return an new one
    subscription.bills.new
  end
end
