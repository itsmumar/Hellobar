class ContactListSerializer < ActiveModel::Serializer
  attributes :id, :site_id, :name, :errors, :provider, :data, :double_optin

  def errors
    object.errors.full_messages
  end

  def provider
    object.identity.try(:provider) || 0
  end
end
