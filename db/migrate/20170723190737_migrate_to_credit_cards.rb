class MigrateToCreditCards < ActiveRecord::Migration
  def up
    scope = PaymentMethod.unscoped.preload(:subscriptions, details: :billing_attempts)
    scope.find_each.with_index do |payment_method, i|
      PaymentMethod.transaction do
        details = payment_method.current_details
        data = details.data
        data['address'] ||= data.delete('address1')
        credit_card = CreditCard.create!(data.merge(user: payment_method.user, deleted_at: payment_method.deleted_at))
        payment_method.subscriptions.update_all credit_card_id: credit_card.id
        details.billing_attempts.update_all credit_card_id: credit_card.id
      end
      puts "Updated #{ i } records" if i % 100 == 0
    end
    puts "Updated #{ scope.count } records"
  end

  def down
    BillingAttempt.update_all credit_card_id: nil
    Subscription.update_all credit_card_id: nil
    CreditCard.delete_all
  end
end
