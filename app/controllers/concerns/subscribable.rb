module Subscribable

  # returns object to render and status code
  def subscription_bill_and_status(site, payment_method, billing_params, old_subscription)
    success, bill = update_subscription(site, payment_method, billing_params)

    if success
      site.reload

      is_upgrade = if old_subscription
        Subscription::Comparison.new(old_subscription, site.current_subscription).upgrade?
      else
       true
      end

      response = { bill: bill, site: SiteSerializer.new(site), is_upgrade: is_upgrade, status: :ok }
      response[:old_subscription] = SubscriptionSerializer.new(old_subscription) if old_subscription

      response
    else
      { errors: bill.errors, status: :unprocessable_entity }
    end
  end

  # returns [success, bill]
  def update_subscription(site, payment_method, billing_params)
    subscription = build_subscription_instance(billing_params)

    site.change_subscription(subscription, payment_method)
  end

  def build_subscription_instance(billing_params)
    "Subscription::#{billing_params[:plan].camelize}".constantize.new schedule: billing_params[:schedule]
  end
end
