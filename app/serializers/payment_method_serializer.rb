class PaymentMethodSerializer < ActiveModel::Serializer
  attributes :id, :current_details

  def current_details
    PaymentMethodDetailsSerializer.new(object.current_details).data
  end

  def to_hash
    {
      id: id,
      current_details: current_details
    }
  end
end
