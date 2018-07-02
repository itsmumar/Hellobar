module ServiceProvider::RailsLogger
  def subscribe(*args)
    log :subscribe, *args do
      super
    end
  end

  private

  def log(method, *args)
    tags = "[ServiceProvider] [#{ adapter.class.name.demodulize }] [contact_list:#{ @contact_list&.id }:remote:#{ remote_list_id }]"
    Rails.logger.info "#{ tags } Performing ##{ method } with arguments #{ args.inspect }"
    yield.tap do
      Rails.logger.info "#{ tags } Performed ##{ method } successfully with arguments #{ args.inspect }"
    end
  rescue StandardError => e
    Rails.logger.error "#{ tags } Error on ##{ method } #{ e.inspect }"
    raise e
  end
end
