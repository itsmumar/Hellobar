module Subscribable

  # returns object to render and status code
  def subscription_bill_and_status(site, payment_method, billing_params)
    success, bill = update_subscription(site, payment_method, billing_params)

    if success
      { bill: bill, site: SiteSerializer.new(site.reload), status: :ok }
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
    "Subscription::#{billing_params[:plan].classify}".constantize.new schedule: billing_params[:schedule]
  end
end
