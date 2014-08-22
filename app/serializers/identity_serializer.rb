class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :supports_double_optin, :embed_code, :oauth

  delegate :service_provider, to: :object

  def lists
    if service_provider.respond_to? :lists
      service_provider.lists.map{|l| {:name => l["name"], :id => l["id"]}}
    end
  end

  def supports_double_optin
    service_provider.class.settings[:supports_double_optin]
  end

  def embed_code
    service_provider.embed_code?
  end

  def oauth
    service_provider.oauth?
  end
end
