class ServiceProviders::Email < ServiceProvider
  attr_reader :contact_list, :identity

  delegate :site, to: :identity

  def initialize(opts = {})
    @contact_list = opts[:contact_list]
    @identity = opts[:identity]
  end

  def valid?
    true
  end

  def batch_subscribe
    raise NoMethodError, 'must be implemented'
  end

  def subscribe(list_id, email, name = nil, double_optin = true)
    raise NoMethodError, 'must be implemented'
  end

  def subscriber_statuses(contact_list, emails)
    raise NoMethodError, 'must be implemented'
  end
end
