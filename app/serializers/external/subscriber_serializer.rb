class External::SubscriberSerializer < ActiveModel::Serializer
  attributes :name, :email

  def read_attribute_for_serialization(attribute)
    object.public_send(attribute)
  end
end
