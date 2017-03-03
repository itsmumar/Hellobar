module Subscribable
  # returns object to render and status code
  def subscription_bill_and_status(site, payment_method, billing_params, old_subscription)
    success, bill = update_subscription(site, payment_method, billing_params)

    if success
      site.reload

      track_subscription_change(site, old_subscription)

      is_upgrade = if old_subscription
        Subscription::Comparison.new(old_subscription, site.current_subscription).upgrade?
      else
       true
      end

      track_upgrade if is_upgrade

      response = { bill: bill, site: SiteSerializer.new(site), is_upgrade: is_upgrade, status: :ok }
      response[:old_subscription] = SubscriptionSerializer.new(old_subscription) if old_subscription

      response
    else
      if bill.errors.empty?
        {errors:
          ["There was an error processing your payment.  Please contact your credit card company or try using a different credit card."],
          status: :unprocessable_entity}
      else
        { errors: bill.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  # returns [success, bill]
  def update_subscription(site, payment_method, billing_params)
    subscription = build_subscription_instance(billing_params)
    trial_period = billing_params[:trial_period]
    trial_period = trial_period.blank? ? nil : trial_period.to_i.days
    site.change_subscription(subscription, payment_method, trial_period)
  end

  def build_subscription_instance(billing_params)
    "Subscription::#{billing_params[:plan].camelize}".constantize.new schedule: billing_params[:schedule]
  end

  def track_subscription_change(site, old_subscription)
    props = {}

    if old_subscription
      props[:from_plan] = old_subscription.values[:name]
      props[:from_schedule] = old_subscription.schedule
    end

    if new_subscription = site.current_subscription
      props[:to_plan] = new_subscription.values[:name]
      props[:to_schedule] = new_subscription.schedule
    end

    Analytics.track(:site, site.id, :change_sub, props)
  end

  def track_upgrade
    Analytics.track(*current_person_type_and_id, "Upgraded")
  end
end
