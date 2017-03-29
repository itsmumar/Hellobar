class ContactListSerializer < ActiveModel::Serializer
  attributes(
    :data,
    :double_optin,
    :errors,
    :id,
    :name,
    :provider_name,
    :site_elements_count,
    :site_id
  )

  def errors
    object.errors.full_messages
  end
end
