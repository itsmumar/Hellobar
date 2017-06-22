module Subscribable
  # returns object to render and status code
  def subscription_bill_and_status(site, payment_method, billing_params)
    old_subscription = site.current_subscription
    bill = ChangeSubscription.new(site, billing_params, payment_method).call

    is_upgrade =
      if old_subscription
        Subscription::Comparison.new(old_subscription, bill.subscription).upgrade?
      else
        true
      end

    track_upgrade if is_upgrade

    { bill: bill, site: SiteSerializer.new(site), is_upgrade: is_upgrade, status: :ok }.tap do |response|
      response[:old_subscription] = SubscriptionSerializer.new(old_subscription) if old_subscription
    end
  end

  def track_upgrade
    Analytics.track(*current_person_type_and_id, 'Upgraded')
  end
end
