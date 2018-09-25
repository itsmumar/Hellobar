class UpdateAnnualPrices < ActiveRecord::Migration
  def up
    growth_bills.where(created_before_promotion).update_all amount: 289, base_amount: 289
    pro_bills.where(created_before_promotion).update_all amount: 289, base_amount: 289
    elite_bills.where(created_before_promotion).update_all amount: 999, base_amount: 999

    growth_subscriptions.update_all(['original_amount = amount, amount = ?', 289])
    pro_subscriptions.update_all(['original_amount = amount, amount = ?', 289])
    elite_subscriptions.update_all(['original_amount = amount, amount = ?', 999])
  end

  def bill_scope
    Bill.pending.non_free.joins(:subscription).where('bill_at >= ?', Date.today)
  end

  def growth_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Growth', schedule: 'yearly' })
  end

  def pro_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Pro', schedule: 'yearly' })
  end

  def elite_bills
    bill_scope.where(subscriptions: { type: 'Subscription::Elite', schedule: 'yearly' })
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

  def created_before_promotion
    ['bills.created_at < ?', Date.parse('2018-09-13')]
  end
end
