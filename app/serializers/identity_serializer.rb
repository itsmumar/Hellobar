class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :tags, :supports_double_optin, :embed_code, :oauth,
    :supports_cycle_day

  delegate :lists, :tags, to: :service_provider

  def supports_double_optin
    service_provider.config.supports_double_optin
  end

  def supports_cycle_day
    service_provider.name == :get_response
  end

  def embed_code
  end

  def oauth
    # service_provider.oauth?
  end

  private

  def service_provider
    @service_provider ||= ServiceProviders::Provider.new(object)
  end
end
