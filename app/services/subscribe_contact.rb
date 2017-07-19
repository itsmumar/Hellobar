class SubscribeContact
  # @return [SubscribeContactWorker::Contact]
  def initialize(contact)
    @contact_list = contact.contact_list
    @provider = ServiceProvider.new(contact_list.identity, contact_list)
    @email = contact.email
    @name = contact.fields
  end

  def call
    clear_contact_list_cache
    with_log_entry do
      provider.subscribe(email: email, name: name)
    end
  end

  private

  attr_reader :email, :name, :contact_list, :provider

  def with_log_entry
    log_entry = contact_list.contact_list_logs.create!(email: email, name: name)
    yield
    log_entry.update(completed: true)
  rescue ServiceProvider::InvalidSubscriberError => e
    log_entry.update(completed: false, error: e.to_s)
  rescue => e
    log_entry.update(completed: false, error: e.to_s)
    raven_log e
  end

  def clear_contact_list_cache
    DynamoDB.clear_cache(contact_list.cache_key)
    DynamoDB.clear_cache(contact_list.site.cache_key)
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
