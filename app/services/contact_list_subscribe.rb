class ContactListSubscribe
  DEFAULT_PARAMS = {
    provider: 'webhooks',
    webhook_method: 'POST'
  }

  ValidationError = Class.new(StandardError)

  def initialize(contact_list, params)
    @contact_list = contact_list
    @params = DEFAULT_PARAMS.merge(params.symbolize_keys)
  end

  def call
    validate_params!
    update_contact_list
  end

  private

  attr_reader :contact_list, :params

  def validate_params!
    raise ValidationError.new("not supported provider '#{ params[:provider] }'") unless webhooks_provider?
    raise ValidationError.new("webhook_url is required") if params[:webhook_url].blank?
  end

  def webhooks_provider?
    ServiceProvider::Adapters.fetch(params[:provider]) <= ServiceProvider::Adapters::Webhook
  end

  def find_or_create_identity
    contact_list.site.identities.find_or_create_by!(provider: params[:provider])
  end

  def update_contact_list
    contact_list.update(data: params.slice(:webhook_url, :webhook_method), identity: find_or_create_identity)
  end
end
