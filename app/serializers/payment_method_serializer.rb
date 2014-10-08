class PaymentMethodSerializer < ActiveModel::Serializer
  attributes :current_details

  def current_details
    PaymentMethodDetailsSerializer.new(object.current_details)
  end
end
