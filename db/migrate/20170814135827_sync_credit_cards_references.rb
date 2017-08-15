class SyncCreditCardsReferences < ActiveRecord::Migration
  def up
    BillingAttempt.where(credit_card_id: nil).where.not(payment_method_details_id: nil).find_each do |record|
      record.update_column(
        :credit_card_id,
        CreditCard.where(details_id: record.payment_method_details_id).first&.id
      )
    end

    Subscription.where(credit_card_id: nil).where.not(payment_method_id: nil).find_each do |record|
      method = PaymentMethod.find(record.payment_method_id)
      details_id = method.current_details&.id
      record.update_column(
        :credit_card_id,
        CreditCard.where(details_id: details_id).first&.id
      )
    end
  end
end
