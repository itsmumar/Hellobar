class ContactListSerializer < ActiveModel::Serializer
  attributes(
    :data,
    :double_optin,
    :errors,
    :id,
    :name,
    :provider,
    :site_elements_count,
    :site_id
  )

  def errors
    object.errors.full_messages
  end

  def provider
    object.identity.try(:provider) || 0
  end
end
