module ServiceProviders::Rescuable
  extend ActiveSupport::Concern

  def self.prepended(base)
    base.include ActiveSupport::Rescuable
  end

  def lists
    super
  rescue => exception
    rescue_with_handler(exception) || raise
  end

  def subscribe(*)
    super
  rescue => exception
    rescue_with_handler(exception) || raise
  end

  def batch_subscribe(*)
    super
  rescue => exception
    rescue_with_handler(exception) || raise
  end
end
