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
    # to be implemented in a child class
  end

  def subscribe(_list_id, _email, _name = nil, _double_optin = true)
    # to be implemented in a child class
  end

  def subscriber_statuses(_contact_list, _emails)
    # to be implemented in a child class
  end
end
