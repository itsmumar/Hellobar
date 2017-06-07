module ServiceProviders::Logger
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
    tags = "[ServiceProviders] [#{ adapter.class.name.demodulize }] [contact_list:#{ @contact_list&.id }:remote:#{ remote_list_id }]"
    msg = "#{ tags } Performing ##{ method } with arguments #{ args.inspect }"
    Rails.logger.info msg
  end
end
