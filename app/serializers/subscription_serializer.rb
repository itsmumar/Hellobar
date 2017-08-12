class SubscriptionSerializer < ActiveModel::Serializer
  attributes :schedule, :type, :name, :yearly_amount, :monthly_amount
  attributes :trial, :credit_card_id, :credit_card_last_digits
  attributes :payment_valid

  delegate :credit_card, to: :object
  delegate :last_digits, to: :credit_card, prefix: true, allow_nil: true

  def schedule
    object.values[:schedule]
  end

  def name
    object.values[:name]
  end

  def type
    object.values[:name].delete(' ').underscore
  end

  def yearly_amount
    amount = object.class.estimated_price(scope, :yearly)
    amount_to_string(amount)
  end

  def monthly_amount
    amount = object.class.estimated_price(scope, :monthly)
    amount_to_string(amount)
  end

  def payment_method_details_id
    return unless object.payment_method.try(:current_details)
    object.payment_method.current_details.id
  end

  def trial
    object.currently_on_trial?
  end

  def payment_valid
    !object.problem_with_payment?
  end

  private

  def amount_to_string(amount)
    return '' if amount.nil?
    format('%.2f', amount).chomp('.00')
  end
end
