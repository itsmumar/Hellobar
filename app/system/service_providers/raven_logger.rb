module ServiceProviders::RavenLogger
  def lists
    super
  rescue => exception
    raven_log(exception)
    raise exception
  end

  def subscribe(*args)
    super
  rescue => exception
    raven_log(exception, args)
    raise exception
  end

  def batch_subscribe(*args)
    super
  rescue => exception
    raven_log(exception, args)
    raise exception
  end

  private

  def raven_log(exception, args = [])
    options = {
      extra: {
        identity_id: @identity&.id,
        contact_list_id: @contact_list&.id,
        arguments: args,
        double_optin: @contact_list&.double_optin,
        tags: @contact_list&.tags
      },
      tags: { type: 'service_provider', adapter_key: adapter.key, adapter_class: adapter.class.name }
    }

    Raven.capture_exception(exception, options)
  end
end
