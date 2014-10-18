class SubscriptionSerializer < ActiveModel::Serializer
  attributes :schedule, :type, :yearly_amount, :monthly_amount, :payment_method_details_id, :payment_method_number

  def schedule
    object.values[:schedule]
  end

  def type
    object.values[:name].downcase
  end

  def yearly_amount
    object.values[:yearly_amount]
  end

  def monthly_amount
    object.values[:monthly_amount]
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
end
