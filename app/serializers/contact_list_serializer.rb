class ContactListSerializer < ActiveModel::Serializer
  attributes(
    :data,
    :double_optin,
    :errors,
    :id,
    :name,
    :provider_name,
    :provider_token,
    :site_elements_count,
    :site_id,
    :subscribers_count
  )

  def errors
    object.errors.full_messages
  end

  def provider_token
    object&.identity&.provider || '0'
  end

  def subscribers_count
    context && context[object.id]
  end
end
