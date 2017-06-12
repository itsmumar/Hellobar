class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists, :tags,
    :supports_double_optin, :embed_code, :oauth,
    :supports_cycle_day

  delegate :lists, :tags, to: :service_provider

  def supports_double_optin
    service_provider.config.supports_double_optin.present?
  end

  def supports_cycle_day
    service_provider.config.supports_cycle_day.present?
  end

  def embed_code
    service_provider.config.requires_embed_code.present?
  end

  def oauth
    service_provider.config.oauth.present?
  end

  private

  def service_provider
    @service_provider ||= ServiceProvider.new(object)
  end
end
