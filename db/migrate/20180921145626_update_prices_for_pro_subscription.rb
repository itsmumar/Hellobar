class UpdatePricesForProSubscription < ActiveRecord::Migration
  def up
    growth_bills.update_all amount: 29, base_amount: 29
    pro_bills.update_all amount: 29, base_amount: 29
    elite_bills.update_all amount: 99, base_amount: 99

    growth_subscriptions.update_all(['original_amount = amount, amount = ?', 29])
    pro_subscriptions.update_all(['original_amount = amount, amount = ?', 29])
    elite_subscriptions.update_all(['original_amount = amount, amount = ?', 99])
  end

  def bill_scope
    Bill.pending.non_free.joins(:subscription).where('bill_at >= ?', Date.today)
  end

  def growth_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Growth', schedule: 'monthly' })
  end

  def pro_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Pro', schedule: 'monthly' })
  end

  def elite_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Elite', schedule: 'monthly' })
  end

  def growth_subscriptions
    Subscription.where(id: growth_bills.pluck('subscription_id'))
  end

  def pro_subscriptions
    Subscription.where(id: pro_bills.pluck('subscription_id'))
  end

  def elite_subscriptions
    Subscription.where(id: elite_bills.pluck('subscription_id'))
  end
end
