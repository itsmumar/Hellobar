class SubscribeContact
  def initialize(contact)
    @contact_list = contact.contact_list
    @provider = ServiceProvider.new(contact_list.identity, contact_list)
    @email = contact.email
    @name = contact.fields
  end

  def call
    update_contact_list_cache
    subscribe
  end

  private

  attr_reader :email, :name, :contact_list, :provider

  # it updates cache_key and causes cached things to be updated
  def update_contact_list_cache
    contact_list.touch
  end

  def subscribe
    provider.subscribe email: email, name: name

    update_status :synced
  rescue ServiceProvider::InvalidSubscriberError => e
    update_status :error, error: e.to_s
  rescue StandardError => e
    update_status :error, error: e.to_s

    raven_log e
  end

  def update_status status, error: nil
    UpdateContactStatus.new(contact_list.id, email, status, error: error).call
  end

  def raven_log(exception)
    raise exception if Rails.env.development? || Rails.env.test?

    options = {
      extra: {
        identity_id: contact_list.identity&.id,
        contact_list_id: contact_list.id,
        remote_list_id: contact_list.data['remote_id'],
        arguments: { email: email, name: name },
        double_optin: contact_list.double_optin,
        tags: contact_list.tags,
        exception: exception.inspect
      },
      tags: { type: 'service_provider', adapter_key: provider.adapter.key, adapter_class: provider.adapter.class.name }
    }

    Raven.capture_exception(exception, options)
  end
end
