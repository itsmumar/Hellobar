class SyncCreditCardsReferences < ActiveRecord::Migration
  def up
    BillingAttempt.where(credit_card_id: nil).where.not(payment_method_details_id: nil).find_each do |record|
      details = PaymentMethodDetails.find(record.payment_method_details_id)
      credit_card = find_or_create_credit_card(details)
      record.update_column(
        :credit_card_id,
        credit_card.id
      )
    end

    Subscription.where(credit_card_id: nil).where.not(payment_method_id: nil).find_each do |record|
      method = PaymentMethod.find(record.payment_method_id)
      credit_card = find_or_create_credit_card(method.current_details)
      record.update_column(
        :credit_card_id,
        credit_card.id
      )
    end
  end

  def find_or_create_credit_card(details)
    raise 'Details not found' unless details
    credit_card = CreditCard.where(details_id: details.id).first
    return credit_card if credit_card
    create_credit_card(details)
  end

  def create_credit_card(details)
    payment_method = details.payment_method
    data = details.data.dup
    data['number'].gsub! /[^\d]/, ''
    data['address'] ||= data.delete('address1')

    attributes = data.merge(
      details_id: details.id,
      user: payment_method.user,
      deleted_at: payment_method.deleted_at
    )
    CreditCard.create!(attributes)
  end
end
