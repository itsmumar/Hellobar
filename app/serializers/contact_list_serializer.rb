class ContactListSerializer < ActiveModel::Serializer
  attributes(
    :data,
    :double_optin,
    :errors,
    :hidden,
    :id,
    :name,
    :provider_name,
    :provider_token,
    :site_elements_count,
    :site_id
  )

  def errors
    object.errors.full_messages
  end

  def provider_token
    object&.identity&.provider || '0'
  end

  def hidden
    adapter = ServiceProvider.adapter(object.provider_token) rescue nil # rubocop:disable Style/RescueModifier
    adapter&.config&.hidden
  end
end
