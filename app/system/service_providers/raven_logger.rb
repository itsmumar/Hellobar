module ServiceProviders::RavenLogger
  def lists
    super
  rescue => exception
    raven_log(exception)
  end

  def subscribe(*args)
    super
  rescue => exception
    raven_log(exception, args)
  end

  def batch_subscribe(*args)
    super
  rescue => exception
    raven_log(exception, args)
  end

  private

  def raven_log(exception, args = [])
    raise exception if Rails.env.development? || Rails.env.test?

    options = {
      extra: {
        identity_id: @identity&.id,
        contact_list_id: @contact_list&.id,
        remote_list_id: remote_list_id,
        arguments: args,
        double_optin: @contact_list&.double_optin,
        tags: @contact_list&.tags
      },
      tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
    }

    Raven.capture_exception(exception, options)
  end
end
