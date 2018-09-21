class UpdatePricesForProSubscription < ActiveRecord::Migration
  def up
    scope.
      where(subscriptions: { type: 'Subscription::Growth', schedule: 'monthly' }).
      update_all amount: 29

    scope.
      where(subscriptions: { type: 'Subscription::Pro', schedule: 'monthly' }).
      update_all amount: 29

    scope.
      where(subscriptions: { type: 'Subscription::Elite', schedule: 'monthly' }).
      update_all amount: 99
  end

  def scope
    Bill.pending.non_free.joins(:subscription)
  end
end
