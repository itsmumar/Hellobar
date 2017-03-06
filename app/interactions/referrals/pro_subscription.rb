module Referrals::ProSubscription
  def new_pro_subscription
    new_subscription = Subscription::Pro.new
    new_subscription.schedule = 'monthly'
    new_subscription
  end
end
