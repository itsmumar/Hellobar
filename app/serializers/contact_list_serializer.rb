class ContactListSerializer < ActiveModel::Serializer
  attributes :id, :site_id, :name, :errors

  def errors
    object.errors.full_messages
  end
end
