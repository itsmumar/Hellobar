class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :tags, :supports_double_optin, :embed_code, :oauth,
             :supports_cycle_day
  # has_many :contact_lists

  delegate :service_provider, to: :object

  def lists
    if service_provider.respond_to? :lists
      filter_keys(service_provider.lists)
    end
  end

  def tags
    if service_provider.respond_to? :tags
      filter_keys(service_provider.tags)
    end
  end

  def supports_double_optin
    service_provider.class.settings[:supports_double_optin]
  end

  def supports_cycle_day
    service_provider.class == ServiceProviders::GetResponseApi
  end

  def embed_code
    service_provider.embed_code?
  end

  def oauth
    service_provider.oauth?
  end

  private
  def filter_keys(arr)
    arr.map { |a| { :name => a["name"], :id => a["id"] } }
  end
end
