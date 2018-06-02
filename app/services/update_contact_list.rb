class UpdateContactList
  def initialize(contact_list, params)
    @contact_list = contact_list
    @params = params
  end

  def call
    Identity.transaction do
      identity_was = contact_list.identity
      update_contact_list
      destroy_identity_if_necessary(identity_was)
    end
  end

  private

  attr_reader :contact_list, :params

  def identity
    if embed_code? || webhooks?
      find_or_create_identity
    else
      params[:identity]
    end
  end

  def embed_code?
    ServiceProvider.embed_code?(params[:provider_token])
  end

  def webhooks?
    params[:provider_token] == 'webhooks'
  end

  def find_or_create_identity
    contact_list.site.identities.find_or_create_by!(provider: params[:provider_token])
  end

  def update_contact_list
    contact_list.update! params.merge(identity: identity)
  end

  def destroy_identity_if_necessary(identity_was)
    return if identity_was.nil?
    return if identity_was == contact_list.identity

    provider = identity_was.service_provider

    # identity for webhook and embed_code providers is a generic stub and shouldn't be cleaned up
    return if provider.config.requires_webhook_url || provider.config.requires_embed_code

    identity_was.destroy!
  end
end
