class External::SubscriberSerializer < ActiveModel::Serializer
  attributes :name, :email, :contact_list

  def read_attribute_for_serialization(attribute)
    scope[attribute].presence || object.public_send(attribute)
  end
end
