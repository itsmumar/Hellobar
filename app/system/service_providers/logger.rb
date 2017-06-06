module ServiceProviders::Logger
  def lists
    super
  end

  def subscribe(*args)
    log :subscribe, *args
    super
  end

  def batch_subscribe(*args)
    log :batch_subscribe, *args
    super
  end

  private

  def log(method, *args)
    tags = "[ServiceProviders] [#{ adapter.class.name.demodulize }] [contact_list:#{ @contact_list&.id }]"
    msg = "#{ tags } Performing ##{ method } with arguments #{ args.inspect }"
    Rails.logger.info msg
  end
end
