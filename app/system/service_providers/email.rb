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
end
