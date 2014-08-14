class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :supports_double_optin

  def lists
    object.service_provider.lists.map{|l| {:name => l["name"], :id => l["id"]}}
  end

  def supports_double_optin
    !!Hellobar::Settings[:identity_providers][object.provider.to_sym][:supports_double_optin]
  end
end
