class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :supports_double_optin

  delegate :service_provider, to: :object

  def lists
    if service_provider.respond_to? :lists
      service_provider.lists.map{|l| {:name => l["name"], :id => l["id"]}}
    end
  end

  def supports_double_optin
    !!Hellobar::Settings[:identity_providers][object.provider.to_sym][:supports_double_optin]
  end
end
