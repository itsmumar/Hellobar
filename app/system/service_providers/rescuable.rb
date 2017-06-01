module ServiceProviders::Rescuable
  def self.prepended(base)
    base.include ActiveSupport::Rescuable
  end

  def lists
    super
  rescue => exception
    rescue_with_handler(:lists, exception)
  end

  def subscribe(*args)
    @arguments = args
    super
  rescue => exception
    rescue_with_handler(:subscribe, exception)
  end

  def batch_subscribe(*args)
    @arguments = args
    super
  rescue => exception
    rescue_with_handler(:batch_subscribe, exception)
  end

  private

  attr_reader :arguments

  # return value of the handler
  def rescue_with_handler(method, exception)
    raise(exception) unless (handler = handler_for_rescue(exception))
    handler.arity != 0 ? handler.call(method, exception) : handler.call
  end
end
