module ServiceProviders::Rescuable
  def self.prepended(base)
    base.include ActiveSupport::Rescuable
  end

  def lists
    super
  rescue => exception
    rescue_with_handler(exception)
  end

  def subscribe(*args)
    super
  rescue => exception
    rescue_with_handler(exception)
  end

  def batch_subscribe(*args)
    super
  rescue => exception
    rescue_with_handler(exception)
  end

  private

  # override ActiveSupport::Rescuable#rescue_with_handler and return value of the handler
  def rescue_with_handler(exception)
    raise(exception) unless (handler = handler_for_rescue(exception))
    handler.arity != 0 ? handler.call(exception) : handler.call
  end
end
