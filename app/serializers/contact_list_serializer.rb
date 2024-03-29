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
    :site_id,
    :icon_path
  )

  def errors
    object.errors.full_messages
  end

  def provider_token
    object&.identity&.provider || '0'
  end

  def icon_path
    object&.provider_icon_path
  end

  def hidden
    provider = object.provider_token || object.identity&.provider
    return unless ServiceProvider::Adapters.exists?(provider)

    adapter = ServiceProvider::Adapters.fetch(provider)
    adapter.config&.hidden
  end
end
