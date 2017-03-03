class SubscriptionSerializer < ActiveModel::Serializer
  attributes :schedule, :type, :yearly_amount, :monthly_amount
  attributes :is_trial, :payment_method_details_id, :payment_method_number
  attributes :payment_valid

  def schedule
    object.values[:schedule]
  end

  def type
    object.values[:name].downcase
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
    if object.payment_method.try(:current_details)
      object.payment_method.current_details.id
    else
      nil
    end
  end

  def payment_method_number
    if object.payment_method.try(:current_details)
      (object.payment_method.current_details.data.try(:[], "number") || "")[-4..-1]
    else
      nil
    end
  end

  def is_trial
    object.currently_on_trial?
  end

  def payment_valid
    !object.problem_with_payment?
  end

  private

  def amount_to_string(amount)
    return "" if amount.nil?
    ('%.2f' % amount).to_s.chomp(".00")
  end
end
