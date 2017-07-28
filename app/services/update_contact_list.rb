class UpdateContactList
  def initialize(contact_list, params)
    @contact_list = contact_list
    @params = params
  end

  def call
    destroy_identity_if_necessary
    update_contact_list
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
    contact_list.update_attributes(params.merge(identity: identity))
  end

  def destroy_identity_if_necessary
    return if contact_list.identity.nil? || params[:identity] == contact_list.identity

    # will destroy when:
    # 1) passed params[:identity] is nil and there is an existing identity
    # 2) passed params[:identity] is different than the existing one
    contact_list.identity.destroy
  end
end
